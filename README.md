# IA Chatbot in ooHG

[![PayPal](https://img.shields.io/badge/PayPal-donate-blue)](https://www.paypal.com/donate/?hosted_button_id=P3TK84JYLNUU6)

AI Chatbot desktop application written in Harbour/ooHG with async Ollama integration, RAG support, and proper UTF-8 handling for accented characters.

## Features

- **AI Chat**: Conversational interface with Ollama local/cloud models
- **RAG Knowledge Base**: Upload code and documents (.prg, .js, .php, .py, .html, .css, .json, .sql, .md, .txt, etc.) for context-aware programming assistance
- **Async Response Handling**: Non-blocking UI while waiting for Ollama responses, with animated status dots and elapsed time counter
- **UTF-8 Support**: Proper display of accented characters (á, é, í, ó, ú, ñ) and common Unicode symbols (->, <-, bullets, etc.)
- **Model Selection**: Choose from any Ollama model (local or cloud endpoints like `:cloud` models)
- **Configurable Parameters**: Temperature and max tokens sliders

## Requirements

- **Windows** (desktop application)
- **Ollama** running locally (https://ollama.com)
- **Harbour Compiler** (https://harbour.github.io/)
- **ooHG** GUI framework (https://oohg.org/)
- **MinGW** or compatible C compiler (for linking)

## Compilation

### 1. Install dependencies

Download and install:
- Harbour compiler: https://github.com/harbour/core/releases
- ooHG: https://github.com/oohg/oohg/releases
- MinGW (if not included with ooHG)

### 2. Get include paths

Typical installation paths:
```
harbour = C:\hb32\bin\harbour.exe
oohg    = C:\oohg\include
harbour_includes = C:\hb32\include
```

### 3. Compile

```batch
@echo off
set HARBOUR=C:\hb32\bin\harbour.exe
set OOHG=C:\oohg
set HBINC=C:\hb32\include

"%HARBOUR%" iacb.prg ^
  -I"%OOHG%\include%" ^
  -I"%HBINC%" ^
  -o.\obj\

if errorlevel 1 goto end

gcc -shared -mwindows ^
  -I"%OOHG%\include%" ^
  -I"%HBINC%" ^
  -L"%OOHG%\lib%" ^
  -L"%HBINC%\lib%" ^
  .\obj\*.c ^
  -liohb24 ^
  -lxml2 ^
  -lws2_32 ^
  -lwininet ^
  -lole32 ^
  -luuid ^
  -o iacb.exe

:end
pause
```

### 4. Run

```batch
iacb.exe
```

## Usage

### First Run
1. Make sure Ollama is running: `ollama serve`
2. Start `iacb.exe`
3. The application will auto-detect installed Ollama models and populate the dropdown

### Chat
- Type your message and press Enter or click Send
- The animated status shows dots ("Waiting for Ollama response...") and elapsed time ("Thinking... 10s")
- Select a model from the dropdown (e.g., `minimax-m2.7:cloud` for cloud models)

### Knowledge Base (RAG)
1. Create a `docs\` folder next to `iacb.exe`
2. Add your source files (.prg, .js, .php, .py, .html, .css, .json, .sql, .md, .txt, etc.)
3. Check the "Knowledge Base" checkbox
4. The app will index all files and use them as context for queries

### Model Selection
- **Local models**: Standard Ollama models (e.g., `codellama:7b`, `qwen3:14b`)
- **Cloud models**: Models with `:cloud` suffix (e.g., `minimax-m2.7:cloud`, `glm-5.1:cloud`)
- Cloud models require Ollama configured with the appropriate API endpoint

## Project Structure

```
IA-chatbot-ooHG/
  iacb.prg     - Main application source (2000+ lines)
  docs/        - Knowledge base files (optional)
  iacb.exe     - Compiled executable (not in repo)
```

## Architecture

- **UI Framework**: ooHG (Object Oriented Harbour GUI)
- **HTTP Client**: WinHttp.WinHttpRequest.5.1 via COM
- **Async Pattern**: `oHttp:Open(url, .T.)` with polling loop + `do events`
- **RAG**: Simple fragment-based search with TF-IDF-style scoring
- **UTF-8**: Direct UTF-8 passthrough with Unicode symbol replacement

## Troubleshooting

### UI freezes or "Not Responding" title
- The app uses async mode — the status bar should show "Waiting for Ollama response..." with animated dots
- If window freezes completely, Ollama may be slow or unresponsive

### Accented characters show as ?
- Make sure Ollama returns UTF-8 encoded responses
- The app handles UTF-8 directly without conversion to ANSI

### Model not found (404)
- Run `ollama list` to verify the model is installed
- For cloud models, ensure Ollama is configured with the correct endpoint

### Knowledge base not working
- Create a `docs\` folder with supported file types
- Enable the "Knowledge Base" checkbox
- Restart the application after adding files

## License

MIT License — free to use, modify, and distribute.