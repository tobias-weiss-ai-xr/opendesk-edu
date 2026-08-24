export interface ServiceTool {
  id: string;
  name: string;
  description: string;
  category: 'identity' | 'communication' | 'productivity' | 'knowledge' | 'development' | 'infrastructure';
  status: 'live' | 'beta' | 'planned';
  launchUrl: string;
  ssoEnabled: boolean;
  icon: string;
}

export const services: ServiceTool[] = [
  // ── Identity ──
  {
    id: 'keycloak',
    name: 'Keycloak SSO',
    description: 'Single Sign-On identity provider. Log in once to access all openDesk Edu services with your university account.',
    category: 'identity',
    status: 'live',
    launchUrl: 'https://id.home.opendesk-edu.org/realms/opendesk/account/',
    ssoEnabled: true,
    icon: '🔐',
  },

  // ── Communication ──
  {
    id: 'element',
    name: 'Element Chat',
    description: 'Secure messaging and collaboration powered by Matrix. Real-time chat with end-to-end encryption.',
    category: 'communication',
    status: 'live',
    launchUrl: 'https://chat.home.opendesk-edu.org',
    ssoEnabled: true,
    icon: '💬',
  },

  // ── Productivity ──
  {
    id: 'opencloud',
    name: 'OpenCloud',
    description: 'File storage, sharing, and collaboration. Upload, sync, and share documents with your team.',
    category: 'productivity',
    status: 'live',
    launchUrl: 'https://cloud.home.opendesk-edu.org',
    ssoEnabled: true,
    icon: '☁️',
  },
  {
    id: 'sogo',
    name: 'SOGo Webmail',
    description: 'Web-based email, calendar, and contacts. Access your mailbox from any browser.',
    category: 'productivity',
    status: 'live',
    launchUrl: 'https://mail.home.opendesk-edu.org',
    ssoEnabled: true,
    icon: '📧',
  },
  {
    id: 'openproject',
    name: 'OpenProject',
    description: 'Project management, time tracking, and agile boards. Plan and track your projects collaboratively.',
    category: 'productivity',
    status: 'live',
    launchUrl: 'https://opendesk.home.opendesk-edu.org',
    ssoEnabled: true,
    icon: '📊',
  },

  // ── Knowledge ──
  {
    id: 'xwiki',
    name: 'XWiki',
    description: 'Collaborative wiki for documentation, knowledge sharing, and structured content.',
    category: 'knowledge',
    status: 'live',
    launchUrl: 'https://xwiki.home.opendesk-edu.org',
    ssoEnabled: true,
    icon: '📚',
  },

  // ── Development ──
  {
    id: 'open-webui',
    name: 'Open WebUI',
    description: 'ChatGPT-like interface for local LLMs. Interact with Qwen3 and other models hosted on the cluster.',
    category: 'development',
    status: 'beta',
    launchUrl: 'http://home.opendesk-edu.org:30115',
    ssoEnabled: false,
    icon: '🤖',
  },

  // ── Infrastructure ──
  {
    id: 'argocd',
    name: 'Argo CD',
    description: 'GitOps continuous delivery. Manage and monitor Kubernetes deployments from Git repositories.',
    category: 'infrastructure',
    status: 'live',
    launchUrl: 'https://argocd.home.opendesk-edu.org',
    ssoEnabled: false,
    icon: '🚀',
  },
];

export const staffServices: ServiceTool[] = [
  {
    id: 'sogo-staff',
    name: 'SOGo Staff Mail',
    description: 'Webmail for staff accounts.',
    category: 'productivity',
    status: 'live',
    launchUrl: 'https://sogo-staff.home.opendesk-edu.org',
    ssoEnabled: true,
    icon: '📧',
  },
  {
    id: 'xwiki-staff',
    name: 'XWiki Staff',
    description: 'Wiki for staff collaboration.',
    category: 'knowledge',
    status: 'live',
    launchUrl: 'https://xwiki-staff.home.opendesk-edu.org',
    ssoEnabled: true,
    icon: '📚',
  },
  {
    id: 'sogo-students',
    name: 'SOGo Student Mail',
    description: 'Webmail for student accounts.',
    category: 'productivity',
    status: 'live',
    launchUrl: 'https://sogo-students.home.opendesk-edu.org',
    ssoEnabled: true,
    icon: '📧',
  },
];
