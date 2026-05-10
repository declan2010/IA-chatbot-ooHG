#include "oohg.ch"

// =============================================================================
// AI CHATBOT CVC - Harbour ooHG + Ollama with OPTIMIZED RAG Support
// =============================================================================
// 
// FEATURES:
// ----------------------------------------------------
// 1. AI CHAT - Conversation with Ollama models
// 2. KNOWLEDGE BASE (RAG) - Optimized for programming
// 3. INTERFACE WITHOUT ACCENTS - All messages without accents
// 4. AUTOMATIC DETECTION - Detects programming queries automatically
// 5. CODE OPTIMIZATION - Improvements in search and query processing
//
// NEW FEATURE: Optimization for Programming
// ----------------------------------------------------
// - Checkbox to enable/disable Knowledge Base usage
// - RAG system optimized for source code
// - Automatically detects programming queries
// - Specialized semantic search in code
// - Optimized prompts for software development
// - Automatic indexing of programming files
// - Support for 25+ programming languages
//
// Optimized RAG Flow:
// 1. On activation: The knowledge base is loaded/indexed (only once)
// 2. For each query: Detects if it is a programming query
// 3. Specialized semantic search is applied if it is programming
// 4. Optimized prompt is built for the query type
// 5. The LLM responds using specialized context
//
// Global variables
STATIC oMainWindow, oChatEdit, oInputTextBox, oSendButton
STATIC oModelCombo, oTemperature, oMaxTokens, oStatusLabel, oKBInfo
STATIC oKnowledgeBaseCheck  // Variable for the checkbox

STATIC aModelos := {}

STATIC aHistorial := {}
STATIC nMaxHistorial := 15
STATIC lKnowledgeBaseEnabled := .F.  // Knowledge base state

// Variables for the Optimized Knowledge Base
STATIC aFragmentosKB := {}           // Document fragments
STATIC aArchivosKB := {}             // List of loaded files
STATIC aIndicesKB := {}              // Simple search indices
STATIC lKBInicializada := .F.        // Initialization state
STATIC nArchivos := 0

// NEW VARIABLES FOR PROGRAMMING OPTIMIZATION
STATIC aExtensionesCodigo := {"prg", "hb", "c", "h", "cpp", "hpp", "cs", "java", "js", "ts", "py", "rb", "php", "go", "rs", "swift", "kt", "scala", "r", "sql", "sh", "bat", "ps1", "xml", "json", "yaml", "yml", "html", "css", "scss", "less", "vue", "jsx", "tsx", "dockerfile", "makefile", "gradle", "maven", "md", "txt", "doc"}

STATIC aTerminosProgramacion := {"function", "procedure", "method", "class", "interface", "object", "array", "string", "integer", "boolean", "double", "return", "param", "parameter", "local", "static", "public", "private", "protected", "virtual", "override", "abstract", "import", "include", "require", "using", "namespace", "try", "catch", "throw", "exception", "error", "debug", "test", "unit", "integration", "mock", "stub", "api", "rest", "graphql", "http", "https", "json", "xml", "database", "sql", "nosql", "mongodb", "mysql", "postgresql", "git", "commit", "push", "pull", "branch", "merge", "docker", "kubernetes", "cloud", "aws", "azure", "gcp", "microservices", "endpoint", "middleware", "algorithm", "data structure", "tree", "graph", "hash", "recursion", "iteration", "loop", "condition", "switch"}


PROCEDURE Main()

REQUEST HB_CODEPAGE_ESWIN

HB_CDPSELECT("ESWIN")

HB_LANGSELECT('ES')  

SET LANGUAGE TO SPANISH

SET AUTOADJUST ON

   DEFINE WINDOW cMainWindow obj oMainWindow ;
      TITLE "AI Chatbot CVC - Harbour ooHG + Ollama" ;
      WIDTH 1000 ;
      HEIGHT 850 ;
      MAIN

      @ 10,10 LABEL lblModel ;
         WIDTH 120 ;
         HEIGHT 24 ;
         VALUE "Model:"

      @ 10,140 COMBOBOX cModelCombo obj oModelCombo ;
         WIDTH 250 ;
         ITEMS aModelos ;
         VALUE 1

      @ 10,400 LABEL lblTemp ;
         WIDTH 80 ;
         HEIGHT 24 ;
         VALUE "Temperature:"

      @ 10,490 TEXTBOX txtTemperature obj oTemperature ;
         WIDTH 50 ;
         HEIGHT 24 ;
         VALUE "0.7"

      @ 10,550 LABEL lblTokens ;
         WIDTH 90 ;
         HEIGHT 24 ;
         VALUE "Max Tokens:"

      @ 10,615 TEXTBOX txtMaxTokens obj oMaxTokens ;
         WIDTH 80 ;
         HEIGHT 24 ;
         VALUE "16384" ;
         TOOLTIP "Maximum tokens per response (default: 16384)"

      @ 40,10 FRAME frmOpciones ;
         WIDTH 980 ;
         HEIGHT 90 ;
         CAPTION "Options"

      @ 60,20 BUTTON btnTest ;
         WIDTH 100 ;
         HEIGHT 30 ;
         CAPTION "Test Connection" ;
         TOOLTIP "Test connection with Ollama" ;
         ACTION { || ProbarConexionOllama() }

      @ 60,130 BUTTON btnLoadModel ;
         WIDTH 100 ;
         HEIGHT 30 ;
         CAPTION "Load Model" ;
         TOOLTIP "Download/Load AI model" ;
         ACTION { || CargarModelo() }

      @ 60,240 BUTTON btnClear ;
         WIDTH 100 ;
         HEIGHT 30 ;
         CAPTION "Clear Chat" ;
         TOOLTIP "Clear chat history" ;
         ACTION { || LimpiarChat() }

      @ 60,350 BUTTON btnExit ;
         WIDTH 100 ;
         HEIGHT 30 ;
         CAPTION "Exit" ;
         ACTION { || cMainWindow.Release }

      @ 60,470 CHECKBOX chkKnowledgeBase obj oKnowledgeBaseCheck ;
         CAPTION "Use Knowledge Base (RAG)" ;
         WIDTH 280 ;
         HEIGHT 24 ;              
         on change ( ToggleKnowledgeBase() )

      @ 90,480 LABEL lblKBInfo obj oKBInfo ;
         WIDTH 450 ;
         HEIGHT 24 ;
         VALUE "KB Path: docs/ (0 fragments from 0 files)" ;
         TOOLTIP "Path and status of the knowledge base"

      @ 140,10 FRAME frmChat ;
         WIDTH 950 ;
         HEIGHT 370 ;
         CAPTION "Chat"

      @ 160,20 EDITBOX edtChat obj oChatEdit ;
         WIDTH 940 ;
         HEIGHT 330 ;
         READONLY ;
         VALUE "" ;
         FONT "courier new" ;
         BACKCOLOR {255,255,255,255} ;
         NOHSCROLL 

         
         @ 530,10 EDITBOX txtInput obj oInputTextBox ;
         WIDTH 940 ;
         HEIGHT 110 ;
         VALUE "" ;
         BACKCOLOR {255,255,255,255} ;
         NOHSCROLL
           

      @ 660,10 LABEL lblStatus obj oStatusLabel ;
         WIDTH 940 ;
         HEIGHT 24 ;
         VALUE "" ;
         BACKCOLOR {255,255,0} 
           

      @ 690,880 BUTTON btnSend obj oSendButton ;
         WIDTH 70 ;
         HEIGHT 30 ;
         CAPTION "Send" ;
         ACTION { || ProcesarEntradaUsuario() } 

   END WINDOW

   oInputTextBox:SetFocus()
   CENTER WINDOW cMainWindow
   
   // Load available Ollama models
   CargarModelosOllama()
   
   ACTIVATE WINDOW cMainWindow

RETURN

FUNCTION Winevents()
  do events
RETURN


FUNCTION GetSafeStringValue(oControl)
   LOCAL xValor
   xValor := oControl:Value
   IF VALTYPE(xValor) == "C"
      RETURN AllTrim(xValor)
   ENDIF
   IF VALTYPE(xValor) == "N"
      RETURN LTrim(Str(xValor, 20, 6))
   ENDIF
RETURN ""

FUNCTION GetComboBoxModel(oComboBox)
   LOCAL nIndex
   nIndex := oComboBox:Value
   IF nIndex >= 1 .AND. nIndex <= Len(aModelos)
      RETURN aModelos[nIndex]
   ENDIF
RETURN "codellama:7b"

FUNCTION ToggleKnowledgeBase()
   lKnowledgeBaseEnabled := oKnowledgeBaseCheck:Value
   
   
   IF lKnowledgeBaseEnabled
      oStatusLabel:Value := "Knowledge Base: ENABLED - Using RAG for queries"
      
      // Initialize the knowledge base only if not loaded
      IF !lKBInicializada
         InicializarBaseConocimiento()
         IF Len(aFragmentosKB) == 0
            oStatusLabel:Value := "Knowledge Base enabled - No fragments available"
         ENDIF
      ELSE
      ENDIF
   ELSE
      oStatusLabel:Value := "Knowledge Base: DISABLED - Responses without additional context"
   ENDIF
RETURN

PROCEDURE InicializarBaseConocimiento()
   // Function to initialize/load the knowledge base
   // Loads documents and builds a simple Index for search
   
   LOCAL cDirDocs, aArchivos, cArchivo, cContenido, cMensaje, cPathCompleto
   LOCAL i, aArchivosUnicos, j, cArchivoActual, nContador 
   
   // DEBUG: Immediate message on entry
   
   nArchivos := 0
   
   // Initialize variables
   aArchivos := {}
   aFragmentosKB := {}  // Clear arrays to prevent misalignment
   aArchivosKB := {}
   aIndicesKB := {}
   aArchivosUnicos := {}  // For per-file statistics
   cPathCompleto := ""
   
   
   // Directory where documents are located
   cDirDocs := "docs" + Chr(92)
   
   
   // Check if the directory exists
   IF !DirectoryExists(cDirDocs)
      CrearDirectorioSimple(cDirDocs)
      RETURN
   ELSE
   ENDIF
   
   // Search for text and code files
   aArchivos := ListarArchivosCodigo(cDirDocs)
   
   
   IF Len(aArchivos) == 0
    
      // Mark as initialized even if no files
      lKBInicializada := .T.
      RETURN
   ELSE
      FOR i := 1 TO Len(aArchivos)
      NEXT
   ENDIF
   
   // Load and process each file
   
   FOR i := 1 TO Len(aArchivos)
      // Verify that the element is valid before processing
      IF i <= Len(aArchivos) .AND. VALTYPE(aArchivos[i]) == "C"
         cArchivo := AllTrim(aArchivos[i])
         IF !Empty(cArchivo)
            // Build full path safely
            cPathCompleto := cDirDocs
            IF Right(cPathCompleto, 1) != Chr(92)
               cPathCompleto += Chr(92)
            ENDIF
            cPathCompleto += cArchivo
            
            cContenido := CargarArchivoTexto(cPathCompleto)
            
            IF !Empty(cContenido)
               ProcesarDocumentoCodigoOptimizado(cArchivo, cContenido)
               nArchivos++
            ELSE
            ENDIF
         ENDIF
      ENDIF
   NEXT
   
   // Build search index only if there are fragments
   IF Len(aFragmentosKB) > 0
      ConstruirIndiceKB()
   ELSE
   ENDIF
   
   // Mark as initialized
   lKBInicializada := .T.
   
   // Update knowledge base information
   ActualizarInfoKB()
   
   // Display detailed final summary
   IF Len(aFragmentosKB) > 0
      
      // Per-file statistics
      aArchivosUnicos := {}
      FOR i := 1 TO Len(aArchivosKB)
         cArchivoActual := aArchivosKB[i]
         nContador := 0
         FOR j := 1 TO Len(aArchivosKB)
            IF aArchivosKB[j] == cArchivoActual
               nContador++
            ENDIF
         NEXT
         IF AScan(aArchivosUnicos, cArchivoActual) == 0
            AAdd(aArchivosUnicos, cArchivoActual)
         ENDIF
      NEXT
      
      oStatusLabel:Value := "Knowledge Base: " + LTrim(Str(Len(aFragmentosKB))) + " fragments loaded"
   ELSE
      oStatusLabel:Value := "Knowledge Base: No fragments - Add files in docs/ folder"
   ENDIF
   
RETURN

PROCEDURE LimpiarEstadoKB()
   oStatusLabel:Value := ""
   // Timer cleared
RETURN

PROCEDURE ProcesarEntradaUsuario()
   LOCAL cEntrada, cPromptFinal, cRespuesta, cModelActual, nTempActual, nTokensActual
   LOCAL cHistorialContexto, i, nInicio

   cEntrada := GetSafeStringValue(oInputTextBox)
   IF Empty(cEntrada)
      MsgInfo("Please type something.", "Attention")
      RETURN
   ENDIF

   cModelActual := GetComboBoxModel(oModelCombo)
   nTempActual := Val(GetSafeStringValue(oTemperature))
   IF nTempActual < 0 .OR. nTempActual > 2
      nTempActual := 0.7
   ENDIF
   
   nTokensActual := Val(GetSafeStringValue(oMaxTokens))
   IF nTokensActual <= 0
      // Default value: 16384 tokens
      nTokensActual := 16384
   ENDIF

   oInputTextBox:Value := ""
   oInputTextBox:SetFocus()
   
   AgregarMensajeChat("You", cEntrada)

   // ** SHOW STATUS LABEL **
   oStatusLabel:Value := " AI is processing your request (may take several minutes)..."

   cHistorialContexto := ""
   IF Len(aHistorial) > 0
      nInicio := IF(Len(aHistorial) > (nMaxHistorial * 2), ;
                    Len(aHistorial) - (nMaxHistorial * 2) + 1, 1)
      
      FOR i := nInicio TO Len(aHistorial)
         cHistorialContexto += aHistorial[i] + Chr(13) + Chr(10)
      NEXT
   ENDIF

   cPromptFinal := ""
   
   // ** CORRECTED LOGIC FOR RAG - ALWAYS USE KNOWLEDGE BASE WHEN ACTIVATED **
   IF lKnowledgeBaseEnabled
      // Always search the knowledge base, regardless of query type
      cPromptFinal := ConstruirPromptProgramacion(cEntrada, cHistorialContexto, BuscarEnBaseConocimientoOptimizado(cEntrada))
   ELSE
      cPromptFinal := ConstruirPromptProgramacion(cEntrada, cHistorialContexto, {})
   ENDIF

   oSendButton:Enabled := .F.
   oInputTextBox:Enabled := .F.

   // Show whether RAG is being used or not
   IF lKnowledgeBaseEnabled
      AgregarMensajeChat("System", "[RAG ENABLED] Using Knowledge Base for the response...", .F.)
   ELSE
      AgregarMensajeChat("System", "[RAG DISABLED] Direct response from model without additional context...", .F.)
   ENDIF
   
   AgregarMensajeChat("AI", "Generating response...", .F.)
   
   // Process pending events to keep UI responsive
   do events
   
   cRespuesta := ObtenerRespuestaOllama(cModelActual, cPromptFinal, nTempActual, nTokensActual)
   
   ReemplazarUltimoMensaje("AI", cRespuesta)
   AgregarSeparador()
   oSendButton:Enabled := .T.
   oInputTextBox:Enabled := .T.
   oInputTextBox:SetFocus()

RETURN

PROCEDURE AgregarSeparador()
   LOCAL cCurrentText
   cCurrentText := oChatEdit:Value
   oChatEdit:Value := cCurrentText + "========================================================================================================================" + Chr(13) + Chr(10)
   
   // Update cursor position and give focus
   nLen := Len(oChatEdit:Value)
   oChatEdit:caretpos(nLen) 
   oChatEdit:SetFocus()
   oInputTextBox:SetFocus()
RETURN


FUNCTION ObtenerRespuestaOllama(cModel, cPrompt, nTemperature, nMaxTokens)
   LOCAL cUrl, cJson, cResponse, cResult, oHttp, lSuccess, nTimeout, lRespuestaRecibida
   
   lSuccess := .F.
   cResult := "Unknown error"
   oHttp := NIL
   nTimeout := 600000  // ** TIMEOUT INCREASED TO 10 MINUTES **
   
   oStatusLabel:Value := "Getting response..."
   
   IF Empty(cModel)
      cModel := "mistral"
   ENDIF
   
   IF Empty(cPrompt)
      RETURN "Error: Empty prompt"
   ENDIF
   
   // LIMIT: Validate prompt length before sending
   IF Len(cPrompt) > 12000
      cPrompt := SubStr(cPrompt, 1, 10000) + "..."
      oStatusLabel:Value := "Prompt truncated due to safety limit"
   ENDIF
   
   // LIMIT: Verify prompt length (Error 400 if too long)
   IF Len(cPrompt) > 10000
      cPrompt := SubStr(cPrompt, 1, 8000) + "..." + Chr(13) + Chr(10) + "RESPONSE:"
   ENDIF

   cUrl := "http://localhost:11434/api/generate"
   cJson := '{"model":"' + EscapeJsonString(cModel) + '",'
   cJson += '"prompt":"' + EscapeJsonString(cPrompt) + '",'
   cJson += '"stream":false,'
   cJson += '"options":{"temperature":' + LTrim(Str(nTemperature, 10, 2)) + ','
   cJson += '"num_predict":' + LTrim(Str(nMaxTokens, 10, 0)) + '}}'

   oHttp := CreateObject("WinHttp.WinHttpRequest.5.1")
   
   IF oHttp == NIL
      cResult := "Error: WinHttpRequest not available"
   ELSE
      // ASYNC mode: Send() returns immediately, polling loop keeps UI alive
      oHttp:SetTimeouts(30000, 30000, 60000, nTimeout)
      
      oHttp:Open("POST", cUrl, .T.)   // .T. = ASYNC - Send() returns immediately
      oHttp:SetRequestHeader("Content-Type", "application/json")
      oHttp:Send(cJson)                  // Does NOT block
      
      // Polling loop keeps UI responsive
      nPollStart := Seconds()
      lRespuestaRecibida := .F.
      nDotCount := 0
      DO WHILE Seconds() - nPollStart < nTimeout / 1000
         do events
         IF oHttp:WaitForResponse(1)
            lRespuestaRecibida := .T.
            EXIT
         ENDIF
         // Update dots every iteration
         nDotCount := (nDotCount + 1) % 4
         DO CASE
         CASE nDotCount == 0
            oStatusLabel:Value := "Waiting for Ollama response"
         CASE nDotCount == 1
            oStatusLabel:Value := "Waiting for Ollama response."
         CASE nDotCount == 2
            oStatusLabel:Value := "Waiting for Ollama response.."
         CASE nDotCount == 3
            oStatusLabel:Value := "Waiting for Ollama response..."
         ENDCASE
         // Show thinking time every 10 seconds
         nElapsed := Seconds() - nPollStart
         IF nElapsed >= 10 .AND. Int(nElapsed/10) > Int((nElapsed-1)/10)
            oStatusLabel:Value := "Thinking... " + LTrim(Str(Int(nElapsed))) + "s"
         ENDIF
      ENDDO
      
      IF lRespuestaRecibida
         IF oHttp:Status == 200
            cResponse := oHttp:ResponseText
            cResult := ProcesarRespuesta(cResponse)
            lSuccess := .T.
         ELSEIF oHttp:Status == 404
            cResult := "Error 404: Model '" + cModel + "' not installed. Run: ollama pull " + cModel
         ELSEIF oHttp:Status == 400
            IF Len(cPrompt) > 8000
               cResult := "Error 400: Prompt too long (" + LTrim(Str(Len(cPrompt))) + " characters). Reduce the query or knowledge base."
            ELSE
               cResult := "Error 400: Malformed request. Check the prompt format."
            ENDIF
         ELSE
            cResult := "HTTP Error " + LTrim(Str(oHttp:Status, 10)) + ": " + oHttp:StatusText
         ENDIF
      ELSE
         cResult := "Error: Timeout exhausted (" + LTrim(Str(nTimeout/1000)) + " seconds)"
      ENDIF
   ENDIF

   IF oHttp != NIL
      oHttp:Abort()
      oHttp := NIL
   ENDIF

RETURN cResult

FUNCTION EscapeJsonString(cString)
   LOCAL cEscaped, i, cChar, nAscii, cHexCode
   
   IF Empty(cString)
      RETURN ""
   ENDIF
   
   cEscaped := ""
   
   FOR i := 1 TO Len(cString)
      cChar := SubStr(cString, i, 1)
      nAscii := Asc(cChar)
      
      DO CASE
      // Control characters
      CASE nAscii < 32
         DO CASE
         CASE nAscii == 8
            cEscaped += "\b"
         CASE nAscii == 9
            cEscaped += "\t"
         CASE nAscii == 10
            cEscaped += "\n"
         CASE nAscii == 12
            cEscaped += "\f"
         CASE nAscii == 13
            cEscaped += "\r"
         OTHERWISE
            
            cHexCode := LTrim(Str(nAscii, 2, 0))
            cEscaped += "\u00" + PadL(cHexCode, 2, "0")
         ENDCASE
      
      // JSON special characters
      CASE cChar == Chr(34)
         cEscaped += Chr(92) + Chr(34)
      CASE cChar == Chr(92)
         cEscaped += Chr(92)
      
      // Normal ASCII characters
      CASE nAscii < 128
         cEscaped += cChar
      
      // Extended Unicode
      OTHERWISE
         // CORRECTED CONVERSION: use PadL() to pad with zeros
         cHexCode := LTrim(Str(nAscii, 4, 0))
         cEscaped += "\u" + PadL(cHexCode, 4, "0")
      ENDCASE
   NEXT
   
RETURN cEscaped

FUNCTION ProcesarRespuesta(cJsonResponse)
   LOCAL nStart, nEnd, cResponse, cBuscar, nPos, nLenResp

   cBuscar := '"response":"'
   nStart := At(cBuscar, cJsonResponse)
   
   IF nStart > 0
      nStart += Len(cBuscar)
      cResponse := SubStr(cJsonResponse, nStart)
      
      nPos := 1
      nLenResp := Len(cResponse)
      nEnd := 0
      
      nIterCount := 0
      DO WHILE nPos <= nLenResp
         nIterCount++
         IF nIterCount >= 500
            do events
            nIterCount := 0
         ENDIF
         IF SubStr(cResponse, nPos, 1) == Chr(34)
            IF nPos == 1 .OR. SubStr(cResponse, nPos - 1, 1) != Chr(92)
               nEnd := nPos
               EXIT
            ENDIF
         ENDIF
         nPos++
      ENDDO
      
      IF nEnd > 0
         cResponse := SubStr(cResponse, 1, nEnd - 1)
         cResponse := FormatearTextoRespuesta(cResponse)
      ELSE
         cResponse := "Error: Incomplete response from server"
      ENDIF
   ELSE
      IF At('"error":', cJsonResponse) > 0
         cResponse := "Model error: " + cJsonResponse
      ELSE
         cResponse := "Unexpected response from server"
      ENDIF
   ENDIF

RETURN cResponse

FUNCTION FormatearTextoRespuesta(cTexto)
   LOCAL cFormateado, nPos, nLen, cHex, nCode, cChar
   
   cFormateado := cTexto
   nLen := Len(cFormateado)
   nPos := 1
   
   nIterCount := 0
   DO WHILE nPos <= nLen
      // Process events every 500 iterations to keep UI responsive
      nIterCount++
      IF nIterCount >= 500
         do events
         nIterCount := 0
      ENDIF
      IF SubStr(cFormateado, nPos, 2) == "\u" .AND. nPos + 5 <= nLen
         cHex := SubStr(cFormateado, nPos + 2, 4)
         IF IsHexadecimal(cHex)
            nCode := HexToDec(cHex)
            cChar := Chr(nCode)
            cFormateado := SubStr(cFormateado, 1, nPos - 1) + cChar + SubStr(cFormateado, nPos + 6)
            nLen := Len(cFormateado)
            nPos += Len(cChar)
            LOOP
         ENDIF
      ENDIF
      nPos++
   ENDDO
   
   cFormateado := StrTran(cFormateado, Chr(92) + "n", Chr(13) + Chr(10))
   cFormateado := StrTran(cFormateado, Chr(92) + "t", "    ")
   cFormateado := StrTran(cFormateado, Chr(92) + Chr(34), Chr(34))
   cFormateado := StrTran(cFormateado, Chr(92) + Chr(92), Chr(92))
   cFormateado := StrTran(cFormateado, Chr(0), "")
   
   // Convert UTF-8 to ANSI to correctly display accents and special characters
   cFormateado := Utf8ToAnsi(cFormateado)
   
RETURN cFormateado

STATIC FUNCTION Utf8ToAnsi(cStr)
   LOCAL cResult := "", i, nLen, nByte, nChar

   nLen := Len(cStr)
   i := 1
   nIterCount := 0
   DO WHILE i <= nLen
      nIterCount++
      IF nIterCount >= 500
         do events
         nIterCount := 0
      ENDIF
      nByte := Asc(SubStr(cStr, i, 1))
      DO CASE
      CASE nByte < 128
         cResult += Chr(nByte)
         i++
      CASE nByte >= 194 .AND. nByte <= 223
         IF i + 1 <= nLen
            nChar := ((nByte - 192) * 64) + (Asc(SubStr(cStr, i + 1, 1)) - 128)
            cResult += Chr(nChar)
         ENDIF
         i += 2
      CASE nByte >= 224 .AND. nByte <= 239
         IF i + 2 <= nLen
            nChar := ((nByte - 224) * 4096) + ((Asc(SubStr(cStr, i + 1, 1)) - 128) * 64) + (Asc(SubStr(cStr, i + 2, 1)) - 128)
            cResult += Chr(nChar)
         ENDIF
         i += 3
      OTHERWISE
         cResult += "?"
         i++
      ENDCASE
   ENDDO

RETURN cResult

FUNCTION IsHexadecimal(cStr)
   LOCAL i, cChar
   
   FOR i := 1 TO Len(cStr)
      cChar := Upper(SubStr(cStr, i, 1))
      IF !IsHexDigit(cChar) .AND. (cChar < "A" .OR. cChar > "F")
         RETURN .F.
      ENDIF
   NEXT
RETURN .T.

FUNCTION HexToDec(cHex)
   LOCAL nResult, i, cChar, nValue
   nResult := 0
   FOR i := 1 TO Len(cHex)
      cChar := Upper(SubStr(cHex, i, 1))
      nValue := IF(IsHexDigit(cChar), Val(cChar), 10 + Asc(cChar) - Asc("A"))
      nResult := nResult * 16 + nValue
   NEXT
RETURN nResult

FUNCTION IsHexDigit(cChar)
RETURN cChar >= "0" .AND. cChar <= "9"

PROCEDURE AgregarMensajeChat(cSender, cMessage, lGuardarHistorial)
   LOCAL cTimestamp, cFormatted, cCurrentText, lGuardar
   
   IF PCount() < 3
      lGuardar := (cSender == "You" .OR. cSender == "AI")
   ELSE
      lGuardar := lGuardarHistorial
   ENDIF
   
   cTimestamp := Time()
   cFormatted := "[" + cTimestamp + "] " + cSender + ": " + cMessage + Chr(13) + Chr(10)
   
   cCurrentText := oChatEdit:Value
   oChatEdit:Value := cCurrentText + cFormatted

   IF lGuardar
      AAdd(aHistorial, cSender + ": " + cMessage)
      DO WHILE Len(aHistorial) > nMaxHistorial * 2
         ADel(aHistorial, 1)
      ENDDO
   ENDIF

   // ** CLEAR LABEL when AI responds **
   IF cSender == "AI" .AND. cMessage != "Generating response..."
      oStatusLabel:Value := ""
   ENDIF

   nLen := Len(oChatEdit:Value)
   oChatEdit:caretpos(nLen) 
   oChatEdit:SetFocus()
   oInputTextBox:SetFocus()

RETURN

PROCEDURE ReemplazarUltimoMensaje(cSender, cMessage)
   LOCAL cCurrent, aLines, cNewContent, i, cLinea
   
   cCurrent := oChatEdit:Value
   aLines := {}
   
   // Manually split into lines
   i := 1
   DO WHILE i <= Len(cCurrent)
      cLinea := ""
      DO WHILE i <= Len(cCurrent) .AND. SubStr(cCurrent, i, 1) != Chr(10)
         cLinea += SubStr(cCurrent, i, 1)
         i++
      ENDDO
      i++  // Skip the line break
      AAdd(aLines, cLinea)
   ENDDO
   
   IF Len(aLines) > 0
      ASize(aLines, Len(aLines) - 1)
   ENDIF
   
   cNewContent := ""
   FOR i := 1 TO Len(aLines)
      cNewContent += aLines[i] + Chr(13) + Chr(10)
   NEXT
   
   oChatEdit:Value := cNewContent
   AgregarMensajeChat(cSender, cMessage)

RETURN

PROCEDURE CargarModelosOllama()
   LOCAL oHttp, cUrl, cResponse, nStatus, n1, n2, cModel
   LOCAL aModelosTemp := {}, i
   
   // If STATIC aModelos is empty, use default
   IF aModelos == NIL .OR. Len(aModelos) == 0
      aModelos := {"minimax-m2:cloud"}
   ENDIF
   
   oHttp := CreateObject("WinHttp.WinHttpRequest.5.1")
   
   IF oHttp == NIL
      DEFAULT aModelos TO {"minimax-m2:cloud"}
      RETURN
   ENDIF
   
   oHttp:SetTimeouts(10000, 10000, 10000, 10000)
   cUrl := "http://localhost:11434/api/tags"
   
   oHttp:Open("GET", cUrl, .F.)
   oHttp:Send()
   
   IF oHttp:WaitForResponse(10)
      IF oHttp:Status == 200
         cResponse := oHttp:ResponseText
         
         // Extract model names from JSON
         n1 := 1
         DO WHILE n1 > 0
            n1 := At('"name":"', cResponse)
            IF n1 > 0
               cResponse := SubStr(cResponse, n1 + 8)
               n2 := At('"', cResponse)
               IF n2 > 0
                  cModel := Left(cResponse, n2 - 1)
                  IF !Empty(cModel) .AND. AScan(aModelosTemp, cModel) == 0
                     AAdd(aModelosTemp, cModel)
                  ENDIF
               ENDIF
            ENDIF
         ENDDO
      ENDIF
   ENDIF
   
   oHttp:Abort()
   oHttp := NIL
   
   // If models were found, use them; if not, use default
   IF Len(aModelosTemp) > 0
      aModelos := {}
      FOR i := 1 TO Len(aModelosTemp)
         AAdd(aModelos, aModelosTemp[i])
      NEXT
   ELSE
      aModelos := {"minimax-m2:cloud"}
   ENDIF
   
   // Reload combo
   oModelCombo:DeleteAllItems()
   FOR i := 1 TO Len(aModelos)
      oModelCombo:AddItem(aModelos[i])
   NEXT
   
   // Select first model
   IF Len(aModelos) > 0
      oModelCombo:Value := 1
   ENDIF

RETURN

PROCEDURE ProbarConexionOllama()
   LOCAL oHttp, cUrl, nStatus, lSuccess
   
   lSuccess := .F.
   
   oHttp := CreateObject("WinHttp.WinHttpRequest.5.1")
   
   IF oHttp == NIL
      AgregarMensajeChat("System", " Component not available")
      RETURN
   ENDIF
   
   oHttp:SetTimeouts(10000, 10000, 10000, 10000)
   cUrl := "http://localhost:11434/api/tags"
   
   oHttp:Open("GET", cUrl, .F.)
   oHttp:Send()
   
   IF oHttp:WaitForResponse(10000)
      nStatus := oHttp:Status
      IF nStatus == 200
         lSuccess := .T.
      ELSE
      ENDIF
   ELSE
   ENDIF
   
   oHttp:Abort()
   oHttp := NIL

RETURN

PROCEDURE LimpiarChat()
   oChatEdit:Value := ""
   aHistorial := {}
   // ** CLEAR LABEL **
   oStatusLabel:Value := ""
   MsgInfo("Chat cleared. Memory history erased.", "Information")
   oInputTextBox:SetFocus()

RETURN

PROCEDURE CargarModelo()
   LOCAL cModelActual, oHttp, cUrl, cJson, cResponse, nStatus, nTimeout, cMensaje
   
   cModelActual := GetComboBoxModel(oModelCombo)
   IF Empty(cModelActual)
      MsgInfo("Please select a model from the list.", "Attention")
      RETURN
   ENDIF
   
   cMensaje := "Download/update model '" + cModelActual + "'?" + Chr(13) + Chr(10) + ;
               "This operation may take several minutes."
   IF !MsgYesNo(cMensaje, "Confirm download")
      RETURN
   ENDIF
   
   oSendButton:Enabled := .F.
   oInputTextBox:Enabled := .F.
   // ** SHOW STATUS LABEL **
   oStatusLabel:Value := " Downloading model '" + cModelActual + "'..."
   
   
   oHttp := CreateObject("WinHttp.WinHttpRequest.5.1")
   IF oHttp == NIL
      HabilitarControles()
      RETURN
   ENDIF
   
   // ** TIMEOUT INCREASED TO 10 MINUTES FOR DOWNLOADS **
   nTimeout := 600000
   oHttp:SetTimeouts(nTimeout, nTimeout, nTimeout, nTimeout)
   
   cUrl := "http://localhost:11434/api/pull"
   cJson := '{"model":"' + EscapeJsonString(cModelActual) + '"}'
   
   oHttp:Open("POST", cUrl, .F.)
   oHttp:SetRequestHeader("Content-Type", "application/json")
   oHttp:Send(cJson)
     
   IF oHttp:WaitForResponse(nTimeout)
      nStatus := oHttp:Status
      
      IF nStatus == 200
         cResponse := oHttp:ResponseText
         IF At('"status":"success"', cResponse) > 0 .OR. At('"status":"pulling', cResponse) > 0
         ELSE
         ENDIF
      ELSEIF nStatus == 400
      ELSEIF nStatus == 404
      ELSE
      ENDIF
   ELSE
   ENDIF
   
   IF oHttp != NIL
      oHttp:Abort()
      oHttp := NIL
   ENDIF
   
   // ** CLEAR LABEL when finished **
   HabilitarControles()
   
RETURN

PROCEDURE HabilitarControles()
   oSendButton:Enabled := .T.
   oInputTextBox:Enabled := .T.
   // ** CLEAR LABEL **
   oStatusLabel:Value := ""
   oInputTextBox:SetFocus()
RETURN

PROCEDURE DetenerProceso()
   MsgInfo("Functionality not implemented.", "Information")
RETURN

// =============================================================================
// OPTIMIZED FUNCTIONS FOR PROGRAMMING
// =============================================================================

FUNCTION DetectarConsultaProgramacion(cQuery)
   // Detects if a query is about programming
   LOCAL aIndicadores := {"code", "code", "function", "function", "method", "method", "algorithm", "program", "develop", "debug", "error", "api", "database", "sql", "class", "class", "object", "variable", "array", "string", "loop", "if", "else", "return", "param", "import", "library", "framework", "test", "unit", "integration", "docker", "git", "javascript", "python", "java", "csharp", "php", "html", "css", "node", "react", "angular", "vue", "crud", "create", "insert", "update", "delete", "function", "procedure", "procedure", "method", "harbour", "clipper", "oohg", "hb", "prg"}
   
   LOCAL cQueryLower := Lower(cQuery)
   LOCAL i
   
   FOR i := 1 TO Len(aIndicadores)
      IF At(aIndicadores[i], cQueryLower) > 0
         RETURN .T.
      ENDIF
   NEXT
   
RETURN .F.

FUNCTION BuscarEnBaseConocimientoOptimizado(cQuery)
   LOCAL aFragmentos, cQueryLower, aPalabras, aResultados, nPuntuacion
   LOCAL i, j, lConsultaProgramacion, cFragmentoActual, cPalabra
   LOCAL nPesoCodigo, nPesoFunciones, nPesoDocumentacion
   
   // DEBUG: Verify if the function is being called
   oStatusLabel:Value := "RAG: Function called - KB initialized: " + IF(lKBInicializada, "YES", "NO") + ", Fragments: " + AllTrim(Str(Len(aFragmentosKB)))
   
   // Detect if it is a programming query
   lConsultaProgramacion := DetectarConsultaProgramacion(cQuery)
   
   // DETECT ENUMERATION QUERIES
   IF At("enumerate", Lower(cQuery)) > 0 .OR. At("list", Lower(cQuery)) > 0 .OR. At("show", Lower(cQuery)) > 0 .OR. At("all", Lower(cQuery)) > 0 .OR. At("functions", Lower(cQuery)) > 0 .OR. At("cyruslib", Lower(cQuery)) > 0
      oStatusLabel:Value := "RAG: Enumeration query detected - using full search"
      // For enumeration queries, use general search which is more permissive
      aFragmentos := BuscarEnBaseConocimiento(cQuery)
      IF Len(aFragmentos) > 0
         oStatusLabel:Value := "RAG ENUMERATION: " + LTrim(Str(Len(aFragmentos))) + " fragments found"
      ELSE
         oStatusLabel:Value := "RAG ENUMERATION: No fragments found"
      ENDIF
      RETURN aFragmentos
   ENDIF
   
   // Improved weights for programming
   nPesoCodigo := 50
   nPesoFunciones := 80
   nPesoDocumentacion := 30
   
   aFragmentos := {}
   
   // If no knowledge base, return empty
   IF !lKBInicializada
      oStatusLabel:Value := "RAG ERROR: Knowledge Base not initialized"
      RETURN aFragmentos
   ENDIF
   
   IF Len(aFragmentosKB) == 0
      oStatusLabel:Value := "RAG ERROR: Knowledge Base empty - Add files in docs/"
      RETURN aFragmentos
   ENDIF
   
   // Prepare query
   cQueryLower := Lower(AllTrim(cQuery))
   aPalabras := ExtraerPalabrasRelevantes(cQueryLower)
   
   aResultados := {}
   
   // Improved search for code
   FOR i := 1 TO Len(aFragmentosKB)
      nPuntuacion := 0
      cFragmentoActual := Lower(aFragmentosKB[i])
      
      // Search by programming keywords
      FOR j := 1 TO Len(aPalabras)
         cPalabra := aPalabras[j]
         
         // Base score for match
         IF At(cPalabra, cFragmentoActual) > 0
            nPuntuacion += Len(cPalabra) * 3
         ENDIF
         
         // Bonus for programming terms
         IF EsTerminoProgramacion(cPalabra)
            nPuntuacion += nPesoCodigo
         ENDIF
         
         // Bonus for function/method names
         IF EsNombreFuncion(cPalabra, cFragmentoActual)
            nPuntuacion += nPesoFunciones
         ENDIF
      NEXT
      
      // Search by code patterns
      nPuntuacion += EvaluarPatronesCodigo(cFragmentoActual)
      
      // Search by file context
      nPuntuacion += EvaluarContextoArchivo(i)
      
      IF nPuntuacion > 0 .OR. (lConsultaProgramacion .AND. (At("enumerate", Lower(cQuery)) > 0 .OR. At("list", Lower(cQuery)) > 0 .OR. At("functions", Lower(cQuery)) > 0))
         // For enumeration queries, include fragments even without score
         IF lConsultaProgramacion .AND. (At("enumerate", Lower(cQuery)) > 0 .OR. At("list", Lower(cQuery)) > 0 .OR. At("functions", Lower(cQuery)) > 0) .AND. nPuntuacion == 0
            nPuntuacion := 1  // Give minimum score to include in enumerations
         ENDIF
         AAdd(aResultados, {i, nPuntuacion})
      ENDIF
   NEXT
   
   // Sort by relevance
   IF Len(aResultados) > 1
      ASort(aResultados, , , { |x, y| x[2] > y[2] })
   ENDIF
   
   // Return best results (maximum 200 for programming, 500 for enumerations)
   nMaxFragmentos := 200
   IF lConsultaProgramacion .AND. (At("enumerate", Lower(cQuery)) > 0 .OR. At("list", Lower(cQuery)) > 0 .OR. At("show", Lower(cQuery)) > 0 .OR. At("functions", Lower(cQuery)) > 0)
      nMaxFragmentos := 500  // More fragments for enumerations
   ENDIF
   
   FOR i := 1 TO Min(Len(aResultados), nMaxFragmentos)
      AAdd(aFragmentos, aFragmentosKB[aResultados[i][1]])
   NEXT
   
   oStatusLabel:Value := "RAG: Searching fragments... (Total in KB: " + AllTrim(Str(Len(aFragmentosKB))) + ")"
   
   IF Len(aFragmentos) > 0
      oStatusLabel:Value := "RAG SUCCESS: " + LTrim(Str(Len(aFragmentos))) + " fragments found"
   ELSE
      oStatusLabel:Value := "RAG WARNING: No relevant fragments - using general knowledge"
      // Fallback to basic search if no optimized results
      aFragmentos := BuscarEnBaseConocimiento(cQuery)
      IF Len(aFragmentos) > 0
         oStatusLabel:Value := "RAG FALLBACK: " + LTrim(Str(Len(aFragmentos))) + " fragments found with basic search"
      ELSE
         oStatusLabel:Value := "RAG ERROR: No fragments found in any search"
      ENDIF
   ENDIF
   
RETURN aFragmentos

FUNCTION ExtraerPalabrasRelevantes(cQueryLower)
   // Extracts relevant words from the query
   LOCAL aPalabras, cPalabraActual, cChar, i
   aPalabras := {}
   cPalabraActual := ""
   
   FOR i := 1 TO Len(cQueryLower)
      cChar := SubStr(cQueryLower, i, 1)
      IF At(cChar, " .,:;!?" + Chr(9)) == 0
         cPalabraActual += cChar
      ELSE
         IF Len(cPalabraActual) > 1
            AAdd(aPalabras, Lower(cPalabraActual))
         ENDIF
         cPalabraActual := ""
      ENDIF
   NEXT
   IF Len(cPalabraActual) > 1
      AAdd(aPalabras, Lower(cPalabraActual))
   ENDIF
   
RETURN aPalabras

FUNCTION EsTerminoProgramacion(cPalabra)
   LOCAL i
   FOR i := 1 TO Len(aTerminosProgramacion)
      IF At(aTerminosProgramacion[i], cPalabra) > 0
         RETURN .T.
      ENDIF
   NEXT
RETURN .F.

FUNCTION EsNombreFuncion(cPalabra, cFragmento)
   // Detects if a word is likely a function name
   IF Len(cPalabra) > 3 .AND. (At("function", cFragmento) > 0 .OR. At("procedure", cFragmento) > 0)
      RETURN .T.
   ENDIF
RETURN .F.

FUNCTION EvaluarPatronesCodigo(cFragmento)
   LOCAL nPuntuacion := 0
   
   // Function patterns
   IF At("function", cFragmento) > 0 .OR. At("procedure", cFragmento) > 0
      nPuntuacion += 40
   ENDIF
   
   // Class patterns
   IF At("class", cFragmento) > 0 .OR. At("object", cFragmento) > 0
      nPuntuacion += 35
   ENDIF
   
   // Control flow patterns
   IF At("if", cFragmento) > 0 .OR. At("else", cFragmento) > 0 .OR. At("for", cFragmento) > 0
      nPuntuacion += 30
   ENDIF
   
   // Data type patterns
   IF At("string", cFragmento) > 0 .OR. At("integer", cFragmento) > 0 .OR. At("boolean", cFragmento) > 0
      nPuntuacion += 25
   ENDIF
   
   // Comment/documentation patterns
   IF At("//", cFragmento) > 0 .OR. At("/*", cFragmento) > 0 .OR. At("**", cFragmento) > 0
      nPuntuacion += 20
   ENDIF
   
   // Harbour/Clipper specific patterns
   IF At("->", cFragmento) > 0 .OR. At("()", cFragmento) > 0
      nPuntuacion += 45
   ENDIF
   
RETURN nPuntuacion

FUNCTION EvaluarContextoArchivo(nIndice)
   LOCAL cArchivo := aArchivosKB[nIndice]
   LOCAL cExtension := GetExtension(cArchivo)
   LOCAL nPuntuacion := 0
   
   // Bonus for code extensions
   IF AScan(aExtensionesCodigo, Lower(cExtension)) > 0
      nPuntuacion += 30
   ENDIF
   
   // Extra bonus for configuration files
   IF At("config", Lower(cArchivo)) > 0 .OR. At("setup", Lower(cArchivo)) > 0
      nPuntuacion += 20
   ENDIF
   
   // Bonus for documentation files
   IF At("readme", Lower(cArchivo)) > 0 .OR. At("doc", Lower(cArchivo)) > 0
      nPuntuacion += 25
   ENDIF
   
RETURN nPuntuacion

FUNCTION GetExtension(cArchivo)
   LOCAL nPos := RAt(".", cArchivo)
   IF nPos > 0
      RETURN SubStr(cArchivo, nPos + 1)
   ENDIF
RETURN ""

FUNCTION ConstruirPromptProgramacion(cEntrada, cHistorialContexto, aFragmentos)
   LOCAL cPrompt, cContexto, i, cFragmento, cArchivoOrigen, nLimitePrompt
   
   // DEBUG: Verify that the function is being called
   oStatusLabel:Value := "BuildPrompt: Called with " + AllTrim(Str(Len(aFragmentos))) + " fragments"
   
   cPrompt := ""
   
   // Knowledge base context
   IF Len(aFragmentos) > 0
      oStatusLabel:Value := "BuildPrompt: Building context with " + AllTrim(Str(Len(aFragmentos))) + " fragments"
      cContexto := ""
      // LIMIT: Only the first 5 fragments to avoid very long prompts
      nLimitePrompt := 5
      // For enumerations, allow more fragments in the prompt
      IF Len(aFragmentos) > 50 .OR. At("enumerate", Lower(cEntrada)) > 0 .OR. At("list", Lower(cEntrada)) > 0 .OR. At("functions", Lower(cEntrada)) > 0
         nLimitePrompt := 100  // More fragments for enumerations
      ENDIF
      FOR i := 1 TO Min(Len(aFragmentos), nLimitePrompt)
         cFragmento := aFragmentos[i]
         
         // Get source file
         IF i <= Len(aArchivosKB)
            cArchivoOrigen := aArchivosKB[i]
         ELSE
            cArchivoOrigen := "unknown"
         ENDIF
         
         // LIMIT: Truncate very long fragments
         IF Len(cFragmento) > 500
            cFragmento := SubStr(cFragmento, 1, 500) + "..."
         ENDIF
         
         cContexto += "=== FRAGMENT " + AllTrim(Str(i)) + " (from " + cArchivoOrigen + ") ===" + Chr(13) + Chr(10) + ;
                     cFragmento + Chr(13) + Chr(10) + Chr(13) + Chr(10)
      NEXT
      
      cPrompt += "=== CODE CONTEXT ===" + Chr(13) + Chr(10) + ;
                cContexto + ;
                "=== PROGRAMMING INSTRUCTIONS ===" + Chr(13) + Chr(10) + ;
                "You are an expert programmer. Analyze the provided code and:" + Chr(13) + Chr(10) + ;
                "- Explain the functionality of each function/class" + Chr(13) + Chr(10) + ;
                "- Identify possible improvements or errors" + Chr(13) + Chr(10) + ;
                "- Provide usage examples when relevant" + Chr(13) + Chr(10) + ;
                "- Use precise technical terminology" + Chr(13) + Chr(10) + ;
                "- Include code snippets in your responses" + Chr(13) + Chr(10) + Chr(13) + Chr(10)
      
   ELSE
      oStatusLabel:Value := "BuildPrompt: NO fragments - Prompt without context"
      cPrompt += "=== PROGRAMMING INSTRUCTIONS ===" + Chr(13) + Chr(10) + ;
                "You are an expert programmer. Respond with:" + Chr(13) + Chr(10) + ;
                "- Clean and well-documented code" + Chr(13) + Chr(10) + ;
                "- Detailed technical explanations" + Chr(13) + Chr(10) + ;
                "- Best practices and design patterns" + Chr(13) + Chr(10) + ;
                "- Practical examples and use cases" + Chr(13) + Chr(10) + Chr(13) + Chr(10)
   ENDIF
   
   // LIMIT: Only last 2 messages from history
   IF !Empty(cHistorialContexto)
      // Truncate history if too long
      IF Len(cHistorialContexto) > 1000
         cHistorialContexto := "..." + SubStr(cHistorialContexto, Len(cHistorialContexto) - 800)
      ENDIF
      cPrompt += "=== CONVERSATION CONTEXT ===" + Chr(13) + Chr(10) + ;
                cHistorialContexto + Chr(13) + Chr(10)
   ENDIF
   
   // LIMIT: Limit total prompt length
   IF Len(cPrompt) > 8000
      cPrompt := SubStr(cPrompt, 1, 7000) + "... (prompt truncated due to limit)" + Chr(13) + Chr(10)
   ENDIF
   
   // Current question
   cPrompt += "=== QUERY ===" + Chr(13) + Chr(10) + cEntrada + Chr(13) + Chr(13) + Chr(10)
   cPrompt += "RESPONSE:"
   
   // DEBUG: Verify the final prompt
   oStatusLabel:Value := "Final prompt: " + AllTrim(Str(Len(cPrompt))) + " characters"
   
RETURN cPrompt

// =============================================================================
// ORIGINAL FUNCTIONS MAINTAINED AND OPTIMIZED
// =============================================================================

FUNCTION ConstruirPromptConRAG(cEntrada, cHistorialContexto)
   LOCAL cPromptRAG, aFragmentos, cContextoKB, i, cFragmento, k, nIndiceReal, cArchivoOrigen
   
   // Search for relevant fragments in the knowledge base
   aFragmentos := BuscarEnBaseConocimiento(cEntrada)
   
   cPromptRAG := ""
   
   // Add knowledge base context if fragments were found
   IF Len(aFragmentos) > 0
      cContextoKB := ""
      // LIMIT: Only the first 5 fragments to avoid very long prompts
      FOR i := 1 TO Min(Len(aFragmentos), 5)
         cFragmento := aFragmentos[i]
         // Get the real index of the fragment in the original array
         nIndiceReal := i
         cArchivoOrigen := "unknown"
         
         // Search in the original fragments array
         FOR k := 1 TO Len(aFragmentosKB)
            IF aFragmentosKB[k] == cFragmento
               IF k <= Len(aArchivosKB)
                  cArchivoOrigen := aArchivosKB[k]
               ENDIF
               EXIT
            ENDIF
         NEXT
         
         // LIMIT: Truncate very long fragments
         IF Len(cFragmento) > 500
            cFragmento := SubStr(cFragmento, 1, 500) + "..."
         ENDIF
         
         cContextoKB += "FRAGMENT " + LTrim(Str(i, 2)) + " (from " + cArchivoOrigen + "):" + Chr(13) + Chr(10) + ;
                       cFragmento + Chr(13) + Chr(10) + Chr(13) + Chr(10)
      NEXT
      
      cPromptRAG += "=== KNOWLEDGE BASE CONTEXT ===" + Chr(13) + Chr(10) + ;
                   cContextoKB + ;
                   "=== INSTRUCTIONS ===" + Chr(13) + Chr(10) + ;
                   "Carefully analyze the information from the knowledge base provided above. " + ;
                   "If the answer to the question is found in these fragments, use them specifically. " + ;
                   "If the information is not complete in the fragments, combine it with your general knowledge. " + ;
                   "Always cite or reference the relevant fragments when possible." + Chr(13) + Chr(10) + Chr(13) + Chr(10)
   ELSE
      cPromptRAG += "=== INFORMATION ===" + Chr(13) + Chr(10) + ;
                   "No relevant fragments were found in the knowledge base for this query. " + ;
                   "Respond based exclusively on your general knowledge." + Chr(13) + Chr(10) + Chr(13) + Chr(10)
   ENDIF
   
   // LIMIT: Only last 2 messages from history
   IF !Empty(cHistorialContexto)
      // Truncate history if too long
      IF Len(cHistorialContexto) > 1000
         cHistorialContexto := "..." + SubStr(cHistorialContexto, Len(cHistorialContexto) - 800)
      ENDIF
      cPromptRAG += "=== CONVERSATION CONTEXT ===" + Chr(13) + Chr(10) + ;
                   cHistorialContexto + Chr(13) + Chr(10)
   ENDIF
   
   // LIMIT: Limit total prompt length
   IF Len(cPromptRAG) > 8000
      cPromptRAG := SubStr(cPromptRAG, 1, 7000) + "... (prompt truncated due to limit)" + Chr(13) + Chr(10)
   ENDIF
   
   // Add the current question
   cPromptRAG += "=== CURRENT QUESTION ===" + Chr(13) + Chr(10) + cEntrada + Chr(13) + Chr(13) + Chr(10)
   cPromptRAG += "RESPONSE:"
   
RETURN cPromptRAG

FUNCTION BuscarEnBaseConocimiento(cQuery)
   LOCAL aFragmentos, cQueryLower, aPalabras, cPalabra, aResultados, nPuntuacion
   LOCAL i, j, aOcurrencias, cMensaje, cFragmentoActual, cChar, cPalabraActual, lYaIncluido
   LOCAL lConsultaEnumeracion, nMaxFragmentos, nMinFragmentos, nLimiteFragmentos, nPuntuacionMinima, nMostrar, nLimiteContexto, nMinFragmentosFinal, nLimiteArbitrario, nMinCaracteres
   
   // Initialize logical variables
   lConsultaEnumeracion := .F.
   lYaIncluido := .F.
   
   aFragmentos := {}
   
   // Verify that the knowledge base is initialized
   IF !lKBInicializada .OR. Len(aFragmentosKB) == 0
      oStatusLabel:Value := "Knowledge base not initialized or empty"
      RETURN aFragmentos
   ENDIF
   
   // Detect if it is an enumeration query
   lConsultaEnumeracion := .F.
   IF At("enumerate", Lower(cQuery)) > 0 .OR. At("list", Lower(cQuery)) > 0 .OR. At("show", Lower(cQuery)) > 0 .OR. At("all", Lower(cQuery)) > 0 .OR. At("functions", Lower(cQuery)) > 0 .OR. At("cyruslib", Lower(cQuery)) > 0
      lConsultaEnumeracion := .T.
   ENDIF
   
   // Initialize numeric variables to prevent errors
   nMaxFragmentos := 40
   nMinFragmentos := 5
   nLimiteFragmentos := 30
   nPuntuacionMinima := 3
   nMostrar := 15
   nLimiteContexto := 10
   nMinFragmentosFinal := 5
   nLimiteArbitrario := 8
   nMinCaracteres := 20
   
   // Informative message
   cMensaje := "Searching Knowledge Base: '" + cQuery + "'"
   oStatusLabel:Value := cMensaje
   
   // Prepare query for search
   IF VALTYPE(cQuery) == "C"
      cQueryLower := Lower(AllTrim(cQuery))
   ELSE
      cQueryLower := Lower(cQuery)
   ENDIF
   // Manually split query into words
   aPalabras := {}
   cPalabraActual := ""
   FOR i := 1 TO Len(cQueryLower)
      cChar := SubStr(cQueryLower, i, 1)
      IF At(cChar, " .,:;!?" + Chr(9)) == 0
         cPalabraActual += cChar
      ELSE
         IF Len(cPalabraActual) > 1
            AAdd(aPalabras, Lower(cPalabraActual))
         ENDIF
         cPalabraActual := ""
      ENDIF
   NEXT
   IF Len(cPalabraActual) > 1
      AAdd(aPalabras, Lower(cPalabraActual))
   ENDIF
   
   // AGGRESSIVE search method to capture content
   aResultados := {}
   
   FOR i := 1 TO Len(aFragmentosKB)
      nPuntuacion := 0  // Always initialize as number
      cFragmentoActual := Lower(aFragmentosKB[i])
      
      // SEARCH BY QUERY WORDS
      FOR j := 1 TO Len(aPalabras)
         cPalabra := aPalabras[j]
         IF Len(cPalabra) >= 1
            // Search the word directly in the fragment
            IF At(cPalabra, cFragmentoActual) > 0
               nPuntuacion += Len(cPalabra) * 2  // Double weight for long words
               
               // Bonus for exact match
               IF cPalabra == Lower(aFragmentosKB[i])
                  nPuntuacion += 20
               ENDIF
            ENDIF
         ENDIF
      NEXT
      
      // SEARCH BY SEMANTIC CONTENT
      // For enumeration queries, give very high base score
      IF lConsultaEnumeracion
         nPuntuacion += 50  // Base score for enumerations
      ENDIF
      
      // Search for programming-related terms
      IF At("function", cFragmentoActual) > 0 .OR. At("function", cFragmentoActual) > 0 .OR. At("method", cFragmentoActual) > 0 .OR. At("method", cFragmentoActual) > 0
         nPuntuacion += 35
      ENDIF
      IF At("crud", cFragmentoActual) > 0 .OR. At("database", cFragmentoActual) > 0 .OR. At("table", cFragmentoActual) > 0 .OR. At("db", cFragmentoActual) > 0
         nPuntuacion += 30
      ENDIF
      IF At("cyrus", cFragmentoActual) > 0
         nPuntuacion += 45
      ENDIF
      IF At("create", cFragmentoActual) > 0 .OR. At("insert", cFragmentoActual) > 0 .OR. At("update", cFragmentoActual) > 0 .OR. At("delete", cFragmentoActual) > 0
         nPuntuacion += 25
      ENDIF
      IF At("lib", cFragmentoActual) > 0 .OR. At("library", cFragmentoActual) > 0
         nPuntuacion += 20
      ENDIF
      
      // EXPANDED SEARCH
      IF At("variable", cFragmentoActual) > 0 .OR. At("parameter", cFragmentoActual) > 0 .OR. At("parameter", cFragmentoActual) > 0
         nPuntuacion += 15
      ENDIF
      IF At("return", cFragmentoActual) > 0 .OR. At("returns", cFragmentoActual) > 0 .OR. At("result", cFragmentoActual) > 0
         nPuntuacion += 15
      ENDIF
      IF At("string", cFragmentoActual) > 0 .OR. At("integer", cFragmentoActual) > 0 .OR. At("boolean", cFragmentoActual) > 0
         nPuntuacion += 12
      ENDIF
      IF At("error", cFragmentoActual) > 0 .OR. At("exception", cFragmentoActual) > 0 .OR. At("handling", cFragmentoActual) > 0
         nPuntuacion += 12
      ENDIF
      
      // SPECIFIC FUNCTION PATTERNS
      IF At("->", cFragmentoActual) > 0  // Harbour function pattern
         nPuntuacion += 25
      ENDIF
      IF At("()", cFragmentoActual) > 0  // Function call pattern
         nPuntuacion += 20
      ENDIF
      IF At("cDatabase", cFragmentoActual) > 0 .OR. At("cTable", cFragmentoActual) > 0 .OR. At("aData", cFragmentoActual) > 0
         nPuntuacion += 15
      ENDIF
      
      // ULTRA AGGRESSIVE SEARCH FOR ENUMERATIONS
      IF lConsultaEnumeracion
         IF At("function", cFragmentoActual) > 0 .OR. At("function", cFragmentoActual) > 0
            nPuntuacion += 100  // Maximum score for functions
         ENDIF
         IF At("Create", cFragmentoActual) > 0 .OR. At("Insert", cFragmentoActual) > 0 .OR. At("Update", cFragmentoActual) > 0 .OR. At("Delete", cFragmentoActual) > 0
            nPuntuacion += 50
         ENDIF
         IF At("Database", cFragmentoActual) > 0 .OR. At("Record", cFragmentoActual) > 0 .OR. At("Table", cFragmentoActual) > 0
            nPuntuacion += 30
         ENDIF
      ENDIF
      
      // ADD ANY FRAGMENT IF IT HAS SCORE OR IS RELEVANT
      IF nPuntuacion >= 1  // Keep very permissive
         AAdd(aResultados, {i, nPuntuacion})
      ENDIF
   NEXT
   
   // AGGRESSIVE FALLBACK: If not enough fragments were found, add many more
   nMinFragmentos := 5
   IF lConsultaEnumeracion
      nMinFragmentos := 20  // For enumerations, expect at least 20 fragments
   ENDIF
   
   IF Len(aFragmentos) < nMinFragmentos
      // For enumeration queries, be much more aggressive
      IF lConsultaEnumeracion
         nLimiteFragmentos := 80
         nPuntuacionMinima := 1  // Accept almost any fragment
      ELSE
         nLimiteFragmentos := 30
         nPuntuacionMinima := 3
      ENDIF
      
      FOR i := 1 TO Len(aFragmentosKB)
         // Verify that it is not already included
         lYaIncluido := .F.
         FOR j := 1 TO Len(aResultados)
            IF aResultados[j][1] == i
               lYaIncluido := .T.
               EXIT
            ENDIF
         NEXT
         
         IF !lYaIncluido
            cFragmento := Lower(aFragmentosKB[i])
            
            // For enumeration queries, include almost any function fragment
            IF lConsultaEnumeracion
               IF At("function", cFragmento) > 0 .OR. At("function", cFragmento) > 0 .OR. At("Create", cFragmento) > 0 .OR. At("Insert", cFragmento) > 0 .OR. At("Update", cFragmento) > 0 .OR. At("Delete", cFragmento) > 0 .OR. At("Database", cFragmento) > 0 .OR. At("Record", cFragmento) > 0
                  AAdd(aResultados, {i, nPuntuacionMinima})
               ELSEIF Len(cFragmento) > 30  // Long fragments of any type
                  AAdd(aResultados, {i, nPuntuacionMinima})
               ENDIF
            ELSE
               // For other queries, be more selective
               IF At("function", cFragmento) > 0 .OR. At("method", cFragmento) > 0 .OR. At("parameter", cFragmento) > 0 .OR. At("return", cFragmento) > 0
                  AAdd(aResultados, {i, 5})  // Medium score for backup fragments
               ENDIF
            ENDIF
         ENDIF
         
         IF Len(aResultados) >= nLimiteFragmentos
            EXIT
         ENDIF
      NEXT
   ENDIF
   
   // Sort by relevance (score)
   IF Len(aResultados) > 1
      ASort(aResultados, , , { |x, y| x[2] > y[2] })
   ENDIF
   
   // Return the best fragments (maximum 500 for enumerations, 40 for other queries)
   nMaxFragmentos := 40
   IF lConsultaEnumeracion
      nMaxFragmentos := 500  // For enumeration queries, include up to 500 fragments
   ENDIF
   
   FOR i := 1 TO Min(Len(aResultados), nMaxFragmentos)
      AAdd(aFragmentos, aFragmentosKB[aResultados[i][1]])
   NEXT
   
   IF Len(aFragmentos) > 0
      IF lConsultaEnumeracion
         oStatusLabel:Value := "ENUMERATION: " + LTrim(Str(Len(aFragmentos))) + " function fragments found"
      ELSE
         oStatusLabel:Value := "Found " + LTrim(Str(Len(aFragmentos))) + " relevant fragments"
      ENDIF
   ELSE
      // If no results, add some fallback fragments
      nLimiteContexto := 10
      IF lConsultaEnumeracion
         nLimiteContexto := 500  // For enumerations, add up to 500 fragments
      ENDIF
      
      FOR i := 1 TO Len(aFragmentosKB)
         IF Len(aFragmentos) >= nLimiteContexto
            EXIT
         ENDIF
         
         cFragmento := Lower(aFragmentosKB[i])
         
         // For enumeration queries, be much less restrictive
         IF lConsultaEnumeracion
            // For enumerations, add almost any substantial fragment
            IF Len(cFragmento) > 10  // Fragments with at least 10 characters
               AAdd(aFragmentos, aFragmentosKB[i])
            ENDIF
         ELSE
            // For other queries, be more selective
            IF At("function", cFragmento) > 0 .OR. At("document", cFragmento) > 0 .OR. At("documentation", cFragmento) > 0 .OR. At("example", cFragmento) > 0
               AAdd(aFragmentos, aFragmentosKB[i])
            ENDIF
         ENDIF
      NEXT
      
      // Update status
      IF Len(aFragmentos) > 0
         IF lConsultaEnumeracion
            oStatusLabel:Value := "ENUMERATION: " + LTrim(Str(Len(aFragmentos))) + " functions added for complete listing"
         ELSE
            oStatusLabel:Value := "Added " + LTrim(Str(Len(aFragmentos))) + " general context fragments"
         ENDIF
      ENDIF
   ENDIF
   
RETURN aFragmentos

FUNCTION BuscarEnIndiceKB(cPalabra)
   LOCAL i, aVacio := {}
   
   // Search word in the index
   FOR i := 1 TO Len(aIndicesKB)
      IF aIndicesKB[i][1] == cPalabra
         RETURN aIndicesKB[i][2]
      ENDIF
   NEXT
   
RETURN aVacio

// =============================================================================
// AUXILIARY FUNCTIONS FOR THE OPTIMIZED KNOWLEDGE BASE
// =============================================================================

FUNCTION DirectoryExists(cDir)
   LOCAL aDirectorio
   // Verify if a directory exists by trying to list its content
   IF Empty(cDir)
      RETURN .F.
   ENDIF
   
   // Ensure it ends with backslash
   IF Right(cDir, 1) != Chr(92)
      cDir += Chr(92)
   ENDIF
   
   // Try to list the directory
   aDirectorio := Directory(cDir + "*.*")
   
   // If no error and we can list the directory, it exists
   RETURN Len(aDirectorio) >= 0
RETURN

FUNCTION CrearDirectorioSimple(cDir)
   IF VALTYPE(cDir) == "C"
      cDir := AllTrim(cDir)
   ENDIF
   IF Right(cDir, 1) != Chr(92)
      cDir += Chr(92)
   ENDIF
RETURN

FUNCTION ListarArchivosCodigo(cDir)
   // Improved function to list code files
   LOCAL aArchivos, i, cExt, cPath, aDirectorio, j
   
   
   aArchivos := {}
   
   FOR i := 1 TO Len(aExtensionesCodigo)
      cExt := aExtensionesCodigo[i]
      cPath := cDir + "*." + cExt
      
      
      aDirectorio := Directory(cPath)
      
      IF Len(aDirectorio) > 0
         FOR j := 1 TO Len(aDirectorio)
            AAdd(aArchivos, aDirectorio[j][1])
         NEXT
      ELSE
      ENDIF
   NEXT
   
   // Ensure it always returns an array
   IF Empty(aArchivos)
      aArchivos := {}
   ENDIF
   
RETURN aArchivos

FUNCTION ListarArchivosTexto(cDir)
   // Original function maintained for compatibility
   RETURN ListarArchivosCodigo(cDir)
RETURN

FUNCTION CargarArchivoTexto(cPathArchivo)
   LOCAL cContenido
   
   // Ensure the parameter is a valid string
   IF VALTYPE(cPathArchivo) != "C" .OR. Empty(cPathArchivo)
      RETURN ""
   ENDIF
   
   cContenido := ""
   
   // Verify if the file exists using Harbour's File()
   IF File(cPathArchivo)
      // Try to read the file
      cContenido := MemoRead(cPathArchivo)
      IF Empty(cContenido)
         cContenido := ""  // Empty but valid file
      ENDIF
   ELSE
      cContenido := ""  // File does not exist
   ENDIF
   
RETURN cContenido

PROCEDURE ProcesarDocumentoCodigoOptimizado(cArchivo, cContenido)
   // Processes code documents with better segmentation
   LOCAL aFragmentos, cLinea, cFragmento, i, nLinea := 1
   LOCAL lEnFuncion := .F., cFuncionActual := "", cDocActual := ""
   LOCAL lEsDocumento := .F.
   
   aFragmentos := {}
   
   // Determine if it is a text or code document
   lEsDocumento := (At("md", Lower(GetExtension(cArchivo))) > 0 .OR. At("txt", Lower(GetExtension(cArchivo))) > 0 .OR. At("doc", Lower(GetExtension(cArchivo))) > 0)
   
   
   IF lEsDocumento
      // For text documents, specialized processing for function lists
      nLinea := 1
      FOR i := 1 TO Len(cContenido)
         IF SubStr(cContenido, i, 1) == Chr(10)
            cLinea := AllTrim(SubStr(cContenido, nLinea, i - nLinea))
            
            // AGGRESSIVE processing for documents
            IF !Empty(cLinea)
               // Process lines containing functions
               IF At("function", Lower(cLinea)) > 0 .OR. At("function", Lower(cLinea)) > 0 .OR. At("cyrus", Lower(cLinea)) > 0
                  AAdd(aFragmentos, cLinea)
               ELSEIF Len(cLinea) > 3  // Reduce threshold for documents
                  // For lines with only function names (lists)
                  IF At("(", cLinea) > 0 .OR. At("()", cLinea) > 0
                     AAdd(aFragmentos, cLinea)
                  ELSEIF At("-", cLinea) > 0 .OR. At("*", cLinea) > 0 .OR. At("1.", cLinea) > 0 .OR. At("2.", cLinea) > 0
                     // List lines (very common in documentation)
                     AAdd(aFragmentos, cLinea)
                  ELSEIF At("A", Upper(cLinea)) == 1 .AND. Len(cLinea) < 50
                     // Possible function names starting with uppercase
                     AAdd(aFragmentos, cLinea)
                  ELSE
                     // Any substantial line
                     AAdd(aFragmentos, cLinea)
                  ENDIF
               ENDIF
            ENDIF
            
            nLinea := i + 1
         ENDIF
      NEXT
      
      // Process last line
      IF nLinea <= Len(cContenido)
         cLinea := AllTrim(SubStr(cContenido, nLinea))
         IF !Empty(cLinea)
            // Apply the same aggressive logic to the last line
            IF At("function", Lower(cLinea)) > 0 .OR. At("function", Lower(cLinea)) > 0 .OR. At("cyrus", Lower(cLinea)) > 0 .OR. Len(cLinea) > 3
               AAdd(aFragmentos, cLinea)
            ENDIF
         ENDIF
      ENDIF
   ELSE
      // For code files, use specialized processing
      FOR i := 1 TO Len(cContenido)
         IF SubStr(cContenido, i, 1) == Chr(10)
            cLinea := SubStr(cContenido, nLinea, i - nLinea)
            ProcesarLineaCodigo(cLinea, @lEnFuncion, @cFuncionActual, @cDocActual, @aFragmentos, cArchivo)
            nLinea := i + 1
         ENDIF
      NEXT
      
      // Process last line
      IF nLinea <= Len(cContenido)
         cLinea := SubStr(cContenido, nLinea)
         ProcesarLineaCodigo(cLinea, @lEnFuncion, @cFuncionActual, @cDocActual, @aFragmentos, cArchivo)
      ENDIF
   ENDIF
   
   // ADDITIONAL SPECIALIZED PROCESSING for cyruslib files
   IF At("cyrus", Lower(cArchivo)) > 0
      // Very aggressive additional processing for cyruslib files
      nLinea := 1
      FOR i := 1 TO Len(cContenido)
         IF SubStr(cContenido, i, 1) == Chr(10)
            cLinea := AllTrim(SubStr(cContenido, nLinea, i - nLinea))
            // Any line containing "function" or that is substantial
            IF !Empty(cLinea) .AND. (At("function", Lower(cLinea)) > 0 .OR. At("cyrus", Lower(cLinea)) > 0 .OR. (Len(cLinea) > 2 .AND. At("(", cLinea) > 0))
               // Verify if not already included
               IF AScan(aFragmentos, cLinea) == 0
                  AAdd(aFragmentos, "CYRUSLIB: " + cLinea)
               ENDIF
            ENDIF
            nLinea := i + 1
         ENDIF
      NEXT
   ENDIF
   
   // Add fragments to the knowledge base
   
   // DEBUG: Show some generated fragments
   FOR i := 1 TO Min(5, Len(aFragmentos))
   NEXT
   
   FOR i := 1 TO Len(aFragmentos)
      AAdd(aFragmentosKB, aFragmentos[i])
      AAdd(aArchivosKB, cArchivo)
   NEXT
RETURN

PROCEDURE ProcesarLineaCodigo(cLinea, lEnFuncion, cFuncionActual, cDocActual, aFragmentos, cArchivo)
   LOCAL cLineaLimpia := AllTrim(cLinea)
   
   // Detect function start
   IF At("FUNCTION", Upper(cLineaLimpia)) > 0 .OR. At("PROCEDURE", Upper(cLineaLimpia)) > 0
      lEnFuncion := .T.
      cFuncionActual := cLineaLimpia
      cDocActual := ""
      
      // Add complete function as fragment
      AAdd(aFragmentos, cFuncionActual)
   ENDIF
   
   // Detect documentation comments
   IF Left(cLineaLimpia, 2) == "//" .OR. Left(cLineaLimpia, 3) == "///"
      cDocActual += " " + SubStr(cLineaLimpia, 3)
   ENDIF
   
   // Detect parameters and types
   IF lEnFuncion .AND. (At("PARAM", Upper(cLineaLimpia)) > 0 .OR. At("LOCAL", Upper(cLineaLimpia)) > 0)
      AAdd(aFragmentos, cLineaLimpia)
   ENDIF
   
   // Detect return
   IF lEnFuncion .AND. At("RETURN", Upper(cLineaLimpia)) > 0
      AAdd(aFragmentos, cLineaLimpia)
      lEnFuncion := .F.
      
      // Add documentation if it exists
      IF !Empty(cDocActual)
         AAdd(aFragmentos, "DOC: " + cDocActual)
      ENDIF
   ENDIF
RETURN

PROCEDURE ProcesarDocumentoKB(cArchivo, cContenido)
   // Original function maintained for compatibility
   // Calls the optimized version
   ProcesarDocumentoCodigoOptimizado(cArchivo, cContenido)
RETURN

PROCEDURE ConstruirIndiceKB()
   LOCAL i, j, cFragmento, aPalabras, cPalabra, cChar, cPalabraActual
   
   aIndicesKB := {}
   
   // Build simple Index based on keywords
   FOR i := 1 TO Len(aFragmentosKB)
      cFragmento := Lower(aFragmentosKB[i])
      
      // Manually split fragment into words
      aPalabras := {}
      cPalabraActual := ""
      FOR j := 1 TO Len(cFragmento)
         cChar := SubStr(cFragmento, j, 1)
         IF At(cChar, " .,:;!?" + Chr(9)) == 0
            cPalabraActual += cChar
         ELSE
            IF Len(cPalabraActual) > 1
               AAdd(aPalabras, Lower(cPalabraActual))
            ENDIF
            cPalabraActual := ""
         ENDIF
      NEXT
      IF Len(cPalabraActual) > 1
         AAdd(aPalabras, Lower(cPalabraActual))
      ENDIF
      
      // Use classic Clipper syntax
      FOR j := 1 TO Len(aPalabras)
         cPalabra := aPalabras[j]
         IF Len(cPalabra) >= 1
            ActualizarIndiceKB(cPalabra, i)
         ENDIF
      NEXT
   NEXT
   
RETURN

PROCEDURE ActualizarIndiceKB(cPalabra, nIndice)
   LOCAL i, aOcurrencias
   
   // Search if the word already exists in the Index
   FOR i := 1 TO Len(aIndicesKB)
      IF aIndicesKB[i][1] == cPalabra
         aOcurrencias := aIndicesKB[i][2]
         IF AScan(aOcurrencias, nIndice) == 0
            AAdd(aOcurrencias, nIndice)
         ENDIF
         RETURN
      ENDIF
   NEXT
   
   // New word in the Index
   aOcurrencias := {nIndice}
   AAdd(aIndicesKB, {cPalabra, aOcurrencias})
RETURN

PROCEDURE ActualizarInfoKB()
   // Function to update the knowledge base information in the interface
   LOCAL cPathCompleto, cInfoKB
   
   // Get the full path of the knowledge base
   cPathCompleto := CurDrive() + ":\" + CurDir() + Chr(92) + "docs" + Chr(92)
   
   // Create the information to display
   IF Len(aFragmentosKB) > 0
      cInfoKB := "KB Path: " + cPathCompleto + " (" + AllTrim(Str(Len(aFragmentosKB))) + " fragments from " + AllTrim(Str(nArchivos)) + " files)"
   ELSE
      cInfoKB := "KB Path: " + cPathCompleto + " (0 fragments from 0 files)"
   ENDIF
   
   // Update the label in the interface
   IF oKBInfo != NIL
      oKBInfo:Value := cInfoKB
   ENDIF
RETURN
