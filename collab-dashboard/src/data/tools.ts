export interface CollabTool {
  id: string;
  name: string;
  description: string;
  coCalcFeature: string;
  category: 'computing' | 'editing' | 'ai' | 'visualization' | 'teaching' | 'infrastructure';
  status: 'stable' | 'beta' | 'planned';
  launchUrl?: string;
  upstreamUrl: string;
}

export const tools: CollabTool[] = [
  {
    id: 'jupyterhub',
    name: 'JupyterHub',
    description: 'Multi-user Jupyter notebooks with kernels for Python, R, Julia, SageMath, and Octave.',
    coCalcFeature: '↔ Jupyter Notebooks',
    category: 'computing',
    status: 'stable',
    launchUrl: 'https://jupyter.opendesk.example.com',
    upstreamUrl: 'https://jupyter.org/hub',
  },
  {
    id: 'overleaf',
    name: 'Overleaf CE',
    description: 'Collaborative LaTeX editor with real-time preview and version control.',
    coCalcFeature: '↔ Collaborative LaTeX',
    category: 'editing',
    status: 'stable',
    launchUrl: 'https://latex.opendesk.example.com',
    upstreamUrl: 'https://github.com/overleaf/overleaf',
  },
  {
    id: 'open-webui',
    name: 'Open WebUI',
    description: 'ChatGPT-like interface for local LLMs powered by Ollama.',
    coCalcFeature: '↔ AI Assistant',
    category: 'ai',
    status: 'beta',
    launchUrl: 'https://ai.opendesk.example.com',
    upstreamUrl: 'https://github.com/open-webui/open-webui',
  },
  {
    id: 'code-server',
    name: 'code-server',
    description: 'VS Code in the browser. Full IDE experience from any device.',
    coCalcFeature: '↔ Python Editor',
    category: 'computing',
    status: 'stable',
    launchUrl: 'https://code.opendesk.example.com',
    upstreamUrl: 'https://github.com/coder/code-server',
  },
  {
    id: 'rstudio',
    name: 'RStudio Server',
    description: 'Integrated development environment for R with Shiny app support.',
    coCalcFeature: '↔ R Statistics',
    category: 'computing',
    status: 'beta',
    launchUrl: 'https://r.opendesk.example.com',
    upstreamUrl: 'https://posit.co/products/open-source/rstudio-server/',
  },
  {
    id: 'ttyd',
    name: 'Web Terminal',
    description: 'Browser-based Linux terminal for command-line access.',
    coCalcFeature: '↔ Linux Terminal',
    category: 'infrastructure',
    status: 'stable',
    launchUrl: 'https://term.opendesk.example.com',
    upstreamUrl: 'https://github.com/tsl0922/ttyd',
  },
  {
    id: 'kasmvnc',
    name: 'KasmVNC Desktop',
    description: 'Full Linux desktop environment accessible from any browser.',
    coCalcFeature: '↔ X11 Desktop',
    category: 'infrastructure',
    status: 'beta',
    launchUrl: 'https://desktop.opendesk.example.com',
    upstreamUrl: 'https://kasmweb.com/',
  },
  {
    id: 'dask',
    name: 'Dask Gateway',
    description: 'Distributed parallel computing clusters for large-scale data processing.',
    coCalcFeature: '↔ Compute Servers',
    category: 'computing',
    status: 'planned',
    launchUrl: 'https://compute.opendesk.example.com',
    upstreamUrl: 'https://gateway.dask.org/',
  },
  {
    id: 'slidev',
    name: 'Slidev',
    description: 'Create beautiful presentations from Markdown files.',
    coCalcFeature: '↔ Slides',
    category: 'editing',
    status: 'beta',
    launchUrl: 'https://slides.opendesk.example.com',
    upstreamUrl: 'https://github.com/slidevjs/slidev',
  },
  {
    id: 'excalidraw',
    name: 'Excalidraw',
    description: 'Collaborative whiteboard for diagrams and sketches.',
    coCalcFeature: '↔ Whiteboard',
    category: 'visualization',
    status: 'stable',
    upstreamUrl: 'https://github.com/excalidraw/excalidraw',
  },
];
