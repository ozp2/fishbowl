# Setting Up Fishbowl

Quick guide to get your thought companion up and running!

## 1. Install Ollama

1. Download from [ollama.com](https://ollama.com/download)
2. Run the installer
3. Open Terminal and check it works:
   ```bash
   ollama --version
   ```

## 2. Get the AI Model

Run this in Terminal:
```bash
ollama pull llama3.2:1b
```

This downloads a ~1.3GB file that powers the analysis.

## 3. Start Ollama

Run this in Terminal:
```bash
ollama serve
```

Keep this window open while using Fishbowl.

## 4. Run Fishbowl

1. Open `fishbowl.xcodeproj` in Xcode
2. Click the ▶️ button to run

## Common Questions

### Analysis Not Working?
1. Make sure Ollama is running (`ollama serve`)
2. Wait a few seconds - first analysis is slower
3. Try the refresh button if needed

### No Themes Showing?
- Write thoughts for 3-5 days
- Themes appear after seeing patterns
- More writing = better insights!

### Want Better Analysis?
Try a bigger model (needs more RAM):
```bash
ollama pull llama3.2:3b  # 2.0GB, better quality
ollama pull llama3.1:8b  # 4.7GB, highest quality
```

Then update the model name in `LLMService.swift`.

### Need Notifications?
1. Click 'Allow' when asked
2. Check System Settings > Notifications > Fishbowl
3. Make sure notifications are enabled

## Tips for Best Results

- Write regularly for better patterns
- Use natural language
- Give it time to learn your style
- Check analysis tab for insights

---

Questions? Open an issue on GitHub! 