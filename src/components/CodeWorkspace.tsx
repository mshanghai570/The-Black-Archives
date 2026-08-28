import React, { useState } from "react";
import { 
  Copy, Check, FileCode, Cpu, Settings, Folder, FolderOpen, 
  ChevronRight, ChevronDown, FileText, FileJson, Search 
} from "lucide-react";
import { SWIFT_SOURCE_FILES, SwiftFile } from "../data/swiftCode";

export default function CodeWorkspace() {
  const [selectedFile, setSelectedFile] = useState<SwiftFile>(SWIFT_SOURCE_FILES[0]);
  const [copied, setCopied] = useState(false);
  const [filterCategory, setFilterCategory] = useState<string>("All");
  const [searchQuery, setSearchQuery] = useState<string>("");

  // Folders expand/collapse state tracker
  const [expandedFolders, setExpandedFolders] = useState<Record<string, boolean>>({
    "App": true,
    "Design": true,
    "Components": true,
    "Views": true,
    "Models": true,
    "ViewModels": true,
    "Services": true,
    "Utilities": true,
    "Resources": true
  });

  const categories = [
    "All", "App", "Design", "Components", "Views", "Models", "ViewModels", "Services", "Utilities", "Resources"
  ];

  const toggleFolder = (folder: string) => {
    setExpandedFolders(prev => ({
      ...prev,
      [folder]: !prev[folder]
    }));
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(selectedFile.code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  // Grouped files by category folder
  const foldersList: { name: string; files: SwiftFile[] }[] = categories
    .filter(cat => cat !== "All")
    .map(cat => {
      const filesInCat = SWIFT_SOURCE_FILES.filter(file => {
        const matchesCategory = file.category === cat;
        const matchesFilter = filterCategory === "All" || filterCategory === cat;
        const matchesSearch = searchQuery === "" || 
          file.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
          file.description.toLowerCase().includes(searchQuery.toLowerCase());
        
        return matchesCategory && matchesFilter && matchesSearch;
      });

      return {
        name: cat,
        files: filesInCat
      };
    })
    .filter(folder => folder.files.length > 0);

  const getFileIcon = (file: SwiftFile, isSelected: boolean) => {
    if (file.language === "json") {
      return <FileJson className={`w-3.5 h-3.5 ${isSelected ? "text-archive-bronze" : "text-archive-amber/70"}`} />;
    }
    if (file.language === "markdown") {
      return <FileText className={`w-3.5 h-3.5 ${isSelected ? "text-archive-bronze" : "text-archive-green/70"}`} />;
    }
    return <FileCode className={`w-3.5 h-3.5 ${isSelected ? "text-archive-bronze" : "text-archive-bronze/60"}`} />;
  };

  return (
    <div className="flex-1 bg-archive-card border border-archive-border rounded-xl overflow-hidden flex flex-col min-h-0 paper-grain">
      {/* Workspace Header */}
      <div className="bg-[#0F1012] px-5 py-4 border-b border-archive-border flex items-center justify-between">
        <div className="flex items-center gap-2 text-left">
          <FileCode className="w-5 h-5 text-archive-bronze" />
          <div>
            <h2 className="text-sm font-serif font-bold text-archive-text">Native iOS Swift Codebase</h2>
            <p className="text-[10px] text-archive-text-muted font-mono uppercase tracking-wider">Xcode 16 directory & modular architecture</p>
          </div>
        </div>
        <div className="text-[10px] bg-archive-panel text-archive-bronze border border-[#2D3136] px-2.5 py-1 rounded font-mono flex items-center gap-1">
          <Cpu className="w-3.5 h-3.5 text-archive-bronze" /> SwiftUI & Swift 6.0
        </div>
      </div>

      {/* Category Pills Selector */}
      <div className="bg-archive-card px-4 py-3 border-b border-archive-border flex gap-2 overflow-x-auto custom-scrollbar">
        {categories.map(cat => (
          <button
            key={cat}
            onClick={() => {
              setFilterCategory(cat);
              const matching = SWIFT_SOURCE_FILES.filter(f => cat === "All" || f.category === cat);
              if (matching.length > 0) {
                setSelectedFile(matching[0]);
              }
            }}
            className={`text-[10px] font-mono px-3 py-1.5 rounded transition-all border shrink-0 ${
              filterCategory === cat
                ? "bg-archive-panel border-archive-bronze text-archive-text font-bold"
                : "bg-[#0F1012]/40 border-archive-border text-archive-text-muted hover:text-archive-text button-depress"
            }`}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Workspace Body: Xcode Sidebar + Code Editor */}
      <div className="flex-1 flex min-h-0 divide-x divide-archive-border">
        
        {/* Xcode-Style Sidebar Directory Explorer */}
        <div className="w-72 bg-[#0F1012]/30 flex flex-col min-h-0">
          
          {/* Sidebar Search Bar */}
          <div className="p-3 border-b border-archive-border/40 bg-[#0F1012]/10 relative">
            <Search className="w-3.5 h-3.5 text-archive-text-muted absolute left-6 top-5.5" />
            <input
              type="text"
              placeholder="Filter files in Xcode project..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-8 pr-3 py-1.5 bg-[#0F1012]/60 rounded border border-archive-border/50 text-[10.5px] font-mono text-archive-text focus:outline-none focus:border-archive-bronze/70 placeholder:text-archive-text-muted/50"
            />
          </div>

          {/* Project Hierarchy Tree Container */}
          <div className="flex-1 overflow-y-auto p-2.5 space-y-1 custom-scrollbar">
            
            {/* Main Project Root Node */}
            <div className="flex items-center gap-1.5 px-1.5 py-1 text-[10px] font-mono font-bold text-archive-bronze uppercase tracking-wider">
              <FolderOpen className="w-3.5 h-3.5 text-archive-bronze" />
              <span>TheBlackArchives</span>
            </div>

            {/* Tree Folder Lists */}
            <div className="pl-2 space-y-1">
              {foldersList.map(folder => {
                const isExpanded = expandedFolders[folder.name] !== false;
                
                return (
                  <div key={folder.name} className="space-y-0.5">
                    {/* Folder Header Row */}
                    <button
                      onClick={() => toggleFolder(folder.name)}
                      className="w-full flex items-center justify-between px-2 py-1.5 rounded hover:bg-archive-panel/20 text-left transition-colors font-mono"
                    >
                      <div className="flex items-center gap-2">
                        {isExpanded ? (
                          <ChevronDown className="w-3 h-3 text-archive-text-muted" />
                        ) : (
                          <ChevronRight className="w-3 h-3 text-archive-text-muted" />
                        )}
                        {isExpanded ? (
                          <FolderOpen className="w-3.5 h-3.5 text-archive-bronze/70" />
                        ) : (
                          <Folder className="w-3.5 h-3.5 text-archive-bronze/60" />
                        )}
                        <span className="text-[11px] font-bold text-archive-text/90">
                          {folder.name}
                        </span>
                      </div>
                      <span className="text-[8px] px-1 bg-archive-panel/60 border border-archive-border/40 text-archive-text-muted rounded font-mono">
                        {folder.files.length}
                      </span>
                    </button>

                    {/* Folder Child Files (indented) */}
                    {isExpanded && (
                      <div className="pl-4 border-l border-archive-border/20 ml-3.5 space-y-0.5">
                        {folder.files.map(file => {
                          const isSelected = selectedFile.path === file.path;
                          return (
                            <button
                              key={file.path}
                              onClick={() => {
                                setSelectedFile(file);
                                setCopied(false);
                              }}
                              className={`w-full group px-2.5 py-1.5 rounded hover:bg-archive-panel/20 text-left flex flex-col gap-0.5 transition-all border ${
                                isSelected 
                                  ? "bg-archive-panel/55 border-archive-border/60 shadow-sm" 
                                  : "border-transparent"
                              }`}
                            >
                              <div className="flex items-center gap-2">
                                {getFileIcon(file, isSelected)}
                                <span className={`text-[10.5px] font-mono font-semibold truncate ${
                                  isSelected ? "text-archive-bronze font-bold" : "text-archive-text-muted group-hover:text-archive-text"
                                }`}>
                                  {file.name}
                                </span>
                              </div>
                              <span className="text-[9px] text-archive-text-muted/75 pl-5 line-clamp-1 group-hover:text-archive-text-muted/95">
                                {file.description}
                              </span>
                            </button>
                          );
                        })}
                      </div>
                    )}
                  </div>
                );
              })}

              {foldersList.length === 0 && (
                <div className="p-4 text-center font-mono text-[10px] text-archive-text-muted italic">
                  No project files matching filters
                </div>
              )}
            </div>

          </div>

          {/* Project Footnote */}
          <div className="p-3 border-t border-archive-border/40 bg-[#0F1012]/30 text-center font-mono text-[8.5px] text-archive-text-muted">
            Xcode Ready Template Directory
          </div>

        </div>

        {/* Dynamic Code Viewer Editor Window */}
        <div className="flex-1 bg-[#0F1012] overflow-hidden flex flex-col min-h-0 relative">
          
          {/* Editor Header Details */}
          <div className="bg-archive-card/60 px-5 py-3 border-b border-archive-border flex items-center justify-between z-10">
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-archive-bronze/80"></span>
              <div className="flex items-center gap-2">
                <span className="text-xs font-mono font-bold text-archive-text">{selectedFile.path}</span>
                <span className="text-[9px] font-mono bg-archive-panel text-archive-text-muted px-1.5 py-0.5 rounded uppercase">{selectedFile.category}</span>
              </div>
            </div>
            
            <button
              onClick={handleCopy}
              className={`text-[10px] font-mono px-3.5 py-1.5 rounded flex items-center gap-1.5 font-semibold transition-all border button-depress ${
                copied 
                  ? "bg-archive-green/10 border-archive-green text-archive-text" 
                  : "bg-archive-panel hover:bg-[#2D3136] text-archive-bronze border-archive-border shadow-md"
              }`}
            >
              {copied ? (
                <>
                  <Check className="w-3.5 h-3.5 text-archive-green" /> COPIED RECORD
                </>
              ) : (
                <>
                  <Copy className="w-3.5 h-3.5" /> COPY RAW CODE
                </>
              )}
            </button>
          </div>

          {/* Actual Code Area with IDE styling */}
          <div className="flex-1 overflow-auto p-5 font-mono text-[11px] text-archive-text-muted text-left select-text relative custom-scrollbar leading-relaxed bg-[#0A0B0C]">
            {/* Custom syntax highlights based on standard Swift / Markdown words */}
            <pre className="whitespace-pre">
              {selectedFile.code.split("\n").map((line, idx) => {
                return (
                  <div key={idx} className="hover:bg-archive-panel/20 px-2 rounded -mx-2 flex">
                    <span className="w-6 text-[#8A6B3D]/50 text-right pr-3 select-none text-[9.5px]">{idx + 1}</span>
                    <span className="flex-1">
                      {line === "" ? " " : highlightSyntax(line, selectedFile.language)}
                    </span>
                  </div>
                );
              })}
            </pre>
          </div>

        </div>

      </div>

    </div>
  );
}

// Simple dynamic regex highlighter matching "The Black Archives" colors
function highlightSyntax(line: string, language: string): React.ReactNode {
  // If markdown or text
  if (language === "markdown") {
    if (line.startsWith("#")) {
      return <span className="text-archive-bronze font-bold">{line}</span>;
    }
    if (line.startsWith("-") || line.startsWith("*") || line.match(/^\d+\./)) {
      return <span className="text-archive-text">{line}</span>;
    }
    return <span>{line}</span>;
  }

  // If JSON
  if (language === "json") {
    const jsonKeywords = line.split(/(".*?"|:|,|\[|\]|\{|\})/);
    return jsonKeywords.map((word, i) => {
      if (word.startsWith('"') && word.endsWith('"')) {
        return <span key={i} className="text-archive-bronze">{word}</span>;
      }
      if (word === ":" || word === "," || word === "{" || word === "}" || word === "[" || word === "]") {
        return <span key={i} className="text-archive-text-muted font-bold">{word}</span>;
      }
      return word;
    });
  }

  // Default Swift Syntax Highlights
  if (line.trim().startsWith("//") || line.trim().startsWith("///")) {
    return <span className="text-archive-green/70 italic">{line}</span>;
  }
  if (line.trim().startsWith("@")) {
    return <span className="text-archive-amber font-bold">{line}</span>;
  }

  // Split and style
  const words = line.split(/(\s+|,|\.|\(|\)|\{|\}|\[|\]|:|;|=|\\)/);
  const swiftKeywords = new Set([
    "import", "struct", "class", "final", "public", "private", "func", "var", "let", "init", 
    "return", "try", "await", "throws", "throw", "guard", "else", "if", "for", "in", "do", "catch",
    "async", "try?", "weak", "self", "mutating", "nil", "extension", "enum", "case", "default"
  ]);
  
  const swiftTypes = new Set([
    "String", "Int", "Float", "Double", "UInt32", "CGSize", "CGImage", "URL", "Data", "Error", "Date",
    "ObservableObject", "View", "Some", "Task", "MainActor", "URLSession", "Combine", "Set", "AnyCancellable",
    "Scene", "App", "Color", "Font", "Toggle", "Button", "Text", "VStack", "HStack", "ScrollView", "Spacer",
    "GeometryReader", "Circle", "Rectangle", "RoundedRectangle", "Label"
  ]);

  return words.map((word, i) => {
    if (swiftKeywords.has(word)) {
      return <span key={i} className="text-archive-bronze font-bold">{word}</span>;
    }
    if (swiftTypes.has(word)) {
      return <span key={i} className="text-archive-text font-bold">{word}</span>;
    }
    if (word.startsWith('"') && word.endsWith('"')) {
      return <span key={i} className="text-archive-green">{word}</span>;
    }
    if (word.match(/^\d+$/)) {
      return <span key={i} className="text-archive-amber font-mono">{word}</span>;
    }
    return word;
  });
}
