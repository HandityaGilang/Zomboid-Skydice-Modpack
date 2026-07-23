using Avalonia;
using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Avalonia.Platform.Storage;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Security.Cryptography;
using System.Threading.Tasks;

namespace SkydiceModpackDownloader
{
    public partial class MainWindow : Window
    {
        private string _modsDir = "";
        private string _manifestUrl = "https://raw.githubusercontent.com/HandityaGilang/Zomboid-Skydice-Modpack/main/manifest.json";
        private string _configPath = "config.json";
        private Dictionary<string, ModFile> _remoteManifest = new();
        private List<string> _filesToDownload = new();
        private List<string> _filesToDelete = new();

        private TextBox ModsFolderTextBox;
        private Button SelectFolderButton;
        private Button CheckButton;
        private Button SyncButton;
        private TextBlock StatusTextBlock;
        private ListBox LogListBox;
        private ProgressBar DownloadProgressBar;
        private TextBlock ProgressTextBlock;

        public MainWindow()
        {
            AvaloniaXamlLoader.Load(this);
            
            ModsFolderTextBox = this.FindControl<TextBox>("ModsFolderTextBox")!;
            SelectFolderButton = this.FindControl<Button>("SelectFolderButton")!;
            CheckButton = this.FindControl<Button>("CheckButton")!;
            SyncButton = this.FindControl<Button>("SyncButton")!;
            StatusTextBlock = this.FindControl<TextBlock>("StatusTextBlock")!;
            LogListBox = this.FindControl<ListBox>("LogListBox")!;
            DownloadProgressBar = this.FindControl<ProgressBar>("DownloadProgressBar")!;
            ProgressTextBlock = this.FindControl<TextBlock>("ProgressTextBlock")!;

            LoadConfig();
            AppLog("Aplikasi dimulai.");
        }

        private void LoadConfig()
        {
            try
            {
                var basePath = AppContext.BaseDirectory;
                _configPath = Path.Combine(basePath, "config.json");

                if (File.Exists(_configPath))
                {
                    var json = File.ReadAllText(_configPath);
                    var config = JsonConvert.DeserializeObject<ConfigData>(json);
                    if (config != null)
                    {
                        if (!string.IsNullOrEmpty(config.manifest_url))
                            _manifestUrl = config.manifest_url;
                        if (!string.IsNullOrEmpty(config.mods_dir))
                            _modsDir = GetSafePath(basePath, config.mods_dir);
                    }
                }
                else
                {
                    // Default config
                    _modsDir = Path.Combine(basePath, "mods");
                    SaveConfig();
                }

                if (!string.IsNullOrEmpty(_modsDir))
                {
                    ModsFolderTextBox.Text = _modsDir;
                }
            }
            catch (Exception ex)
            {
                AppLog("Error loading config: " + ex.Message);
            }
        }

        private void SaveConfig()
        {
            try
            {
                var basePath = AppContext.BaseDirectory;
                var relativeModsDir = Path.GetRelativePath(basePath, _modsDir);
                // Ensure it's not going up the tree
                if (relativeModsDir.StartsWith(".."))
                    relativeModsDir = _modsDir; // Save absolute if relative is unsafe

                var config = new ConfigData
                {
                    manifest_url = _manifestUrl,
                    mods_dir = relativeModsDir
                };
                File.WriteAllText(_configPath, JsonConvert.SerializeObject(config, Formatting.Indented));
            }
            catch (Exception ex)
            {
                AppLog("Error saving config: " + ex.Message);
            }
        }

        private string GetSafePath(string basePath, string relativeOrAbsolutePath)
        {
            if (string.IsNullOrEmpty(relativeOrAbsolutePath)) return basePath;
            if (Path.IsPathRooted(relativeOrAbsolutePath)) return relativeOrAbsolutePath;
            
            var combined = Path.GetFullPath(Path.Combine(basePath, relativeOrAbsolutePath));
            return combined;
        }

        private async void SelectFolderButton_Click(object sender, RoutedEventArgs e)
        {
            var topLevel = TopLevel.GetTopLevel(this);
            if (topLevel == null) return;

            var folders = await topLevel.StorageProvider.OpenFolderPickerAsync(new FolderPickerOpenOptions
            {
                Title = "Pilih Folder Mods",
                AllowMultiple = false
            });

            if (folders.Count > 0)
            {
                var selectedFolder = folders[0].TryGetLocalPath();
                if (!string.IsNullOrEmpty(selectedFolder))
                {
                    _modsDir = selectedFolder;
                    ModsFolderTextBox.Text = _modsDir;
                    SaveConfig();
                    SetStatus("Folder Mods diperbarui.");
                    SyncButton.IsEnabled = false;
                }
            }
        }

        private async void CheckButton_Click(object sender, RoutedEventArgs e)
        {
            SetButtonsEnabled(false);
            try
            {
                if (string.IsNullOrEmpty(_modsDir))
                {
                    SetStatus("Pilih folder Mods terlebih dahulu!");
                    return;
                }

                if (!Directory.Exists(_modsDir))
                {
                    Directory.CreateDirectory(_modsDir);
                }

                SetStatus("Mengunduh manifest...");
                await DownloadManifestAsync();

                SetStatus("Memeriksa file lokal...");
                await CompareFilesAsync();

                if (_filesToDownload.Count == 0 && _filesToDelete.Count == 0)
                {
                    SetStatus("Modpack sudah up-to-date!");
                    SyncButton.IsEnabled = false;
                }
                else
                {
                    SetStatus($"Ditemukan {_filesToDownload.Count} file untuk diunduh, {_filesToDelete.Count} file untuk dihapus.");
                    SyncButton.IsEnabled = true;
                }
            }
            catch (Exception ex)
            {
                SetStatus("Error saat Check. Lihat log.");
                AppLog(ex.ToString());
            }
            finally
            {
                SetButtonsEnabled(true);
            }
        }

        private async void SyncButton_Click(object sender, RoutedEventArgs e)
        {
            SetButtonsEnabled(false);
            try
            {
                // Confirmation for delete
                if (_filesToDelete.Count > 0)
                {
                    // Simple confirm using a quick message, in Avalonia usually requires custom dialog
                    // We'll proceed with deletion but log it. Real app might want a dialog here.
                    SetStatus($"Menghapus {_filesToDelete.Count} file ekstra...");
                    foreach (var file in _filesToDelete)
                    {
                        var fullPath = Path.Combine(_modsDir, file);
                        if (File.Exists(fullPath)) File.Delete(fullPath);
                        else if (Directory.Exists(fullPath)) Directory.Delete(fullPath, true);
                    }
                }

                int count = 0;
                int total = _filesToDownload.Count;

                using var client = new HttpClient();
                foreach (var file in _filesToDownload)
                {
                    count++;
                    SetStatus($"Mengunduh {count}/{total}: {file}");
                    var modFile = _remoteManifest[file];
                    if (string.IsNullOrEmpty(modFile.url)) continue;
                    
                    var url = modFile.url;
                    var destPath = Path.Combine(_modsDir, file);
                    
                    var dir = Path.GetDirectoryName(destPath);
                    if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
                    {
                        Directory.CreateDirectory(dir);
                    }

                    var tempPath = destPath + ".download";
                    
                    try
                    {
                        using var response = await client.GetAsync(url, HttpCompletionOption.ResponseHeadersRead);
                        response.EnsureSuccessStatusCode();
                        
                        var totalBytes = response.Content.Headers.ContentLength ?? -1L;
                        var canReportProgress = totalBytes != -1;

                        using var stream = await response.Content.ReadAsStreamAsync();
                        using var fileStream = new FileStream(tempPath, FileMode.Create, FileAccess.Write, FileShare.None, 8192, true);
                        
                        var buffer = new byte[8192];
                        long totalRead = 0;
                        int bytesRead;

                        while ((bytesRead = await stream.ReadAsync(buffer, 0, buffer.Length)) != 0)
                        {
                            await fileStream.WriteAsync(buffer, 0, bytesRead);
                            totalRead += bytesRead;

                            if (canReportProgress)
                            {
                                var progress = (double)totalRead / totalBytes * 100;
                                UpdateProgress(progress, $"{(totalRead/1024.0/1024.0):F2} MB / {(totalBytes/1024.0/1024.0):F2} MB");
                            }
                        }
                        
                        fileStream.Close();

                        if (File.Exists(destPath)) File.Delete(destPath);
                        File.Move(tempPath, destPath);
                    }
                    catch (Exception ex)
                    {
                        if (File.Exists(tempPath)) File.Delete(tempPath);
                        throw new Exception($"Gagal mengunduh {file}", ex);
                    }
                }

                SetStatus("Sync selesai!");
                UpdateProgress(100, "");
                SyncButton.IsEnabled = false;
            }
            catch (Exception ex)
            {
                SetStatus("Error saat Sync. Lihat log.");
                AppLog(ex.ToString());
            }
            finally
            {
                SetButtonsEnabled(true);
            }
        }

        private async Task DownloadManifestAsync()
        {
            using var client = new HttpClient();
            var json = await client.GetStringAsync(_manifestUrl);
            var manifestData = JsonConvert.DeserializeObject<ManifestData>(json);
            if (manifestData?.files != null)
            {
                _remoteManifest = manifestData.files;
            }
            else
            {
                var dictionaryFallback = JsonConvert.DeserializeObject<Dictionary<string, ModFile>>(json);
                if (dictionaryFallback != null)
                {
                     _remoteManifest = dictionaryFallback;
                }
                else
                {
                    _remoteManifest = new Dictionary<string, ModFile>();
                }
            }
        }

        private async Task CompareFilesAsync()
        {
            _filesToDownload.Clear();
            _filesToDelete.Clear();

            await Task.Run(() => 
            {
                // Check what needs to be downloaded
                foreach (var kvp in _remoteManifest)
                {
                    var relativePath = kvp.Key;
                    var remoteFile = kvp.Value;
                    var fullPath = Path.Combine(_modsDir, relativePath);

                    // Basic security check to prevent directory traversal
                    if (!Path.GetFullPath(fullPath).StartsWith(Path.GetFullPath(_modsDir)))
                    {
                        continue;
                    }

                    if (!File.Exists(fullPath))
                    {
                        _filesToDownload.Add(relativePath);
                    }
                    else
                    {
                        // Optional: Compare Hash. If no hash, compare size, or just re-download if strict.
                        // For simplicity, if hash exists, compare it.
                        if (!string.IsNullOrEmpty(remoteFile.hash))
                        {
                            var localHash = CalculateMD5(fullPath);
                            if (localHash != remoteFile.hash)
                            {
                                _filesToDownload.Add(relativePath);
                            }
                        }
                    }
                }

                // Check what needs to be deleted
                if (Directory.Exists(_modsDir))
                {
                    var localFiles = Directory.GetFiles(_modsDir, "*", SearchOption.AllDirectories);
                    foreach (var file in localFiles)
                    {
                        var relativePath = Path.GetRelativePath(_modsDir, file).Replace("\\", "/");
                        
                        // Ignore our own .download files
                        if (relativePath.EndsWith(".download")) continue;

                        if (!_remoteManifest.ContainsKey(relativePath))
                        {
                            _filesToDelete.Add(relativePath);
                        }
                    }
                }
            });
        }

        private string CalculateMD5(string filename)
        {
            using var md5 = MD5.Create();
            using var stream = File.OpenRead(filename);
            var hash = md5.ComputeHash(stream);
            return BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
        }

        private void SetStatus(string message)
        {
            StatusTextBlock.Text = $"Status: {message}";
            AppLog(message);
        }

        private void UpdateProgress(double percentage, string text)
        {
            DownloadProgressBar.Value = percentage;
            ProgressTextBlock.Text = text;
        }

        private void SetButtonsEnabled(bool isEnabled)
        {
            CheckButton.IsEnabled = isEnabled;
            SelectFolderButton.IsEnabled = isEnabled;
            if (!isEnabled) SyncButton.IsEnabled = false;
        }

        private void Log(string message)
        {
            var logFile = Path.Combine(AppContext.BaseDirectory, "downloader.log");
            File.AppendAllText(logFile, $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {message}{Environment.NewLine}");
        }

        private void AppLog(string message)
        {
            Avalonia.Threading.Dispatcher.UIThread.InvokeAsync(() =>
            {
                var time = DateTime.Now.ToString("HH:mm:ss");
                var logItem = $"[{time}] {message}";
                
                var items = LogListBox.ItemsSource as List<string>;
                if (items == null)
                {
                    items = new List<string>();
                }
                else
                {
                    items = items.ToList(); // clone to avoid mutation issues
                }
                
                items.Add(logItem);
                LogListBox.ItemsSource = items;
                LogListBox.ScrollIntoView(logItem);
            });
            Log(message);
        }
    }

    public class ConfigData
    {
        public string? manifest_url { get; set; }
        public string? mods_dir { get; set; }
    }

    public class ManifestData
    {
        public Dictionary<string, ModFile>? files { get; set; }
    }

    public class ModFile
    {
        public string? url { get; set; }
        public string? hash { get; set; }
    }
}