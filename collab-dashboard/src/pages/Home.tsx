import { services, staffServices } from '../data/tools';
import ServiceCard from '../components/ServiceCard';

const categories = [
  { key: 'identity' as const, label: 'Identity & Access', icon: '🔐' },
  { key: 'communication' as const, label: 'Communication', icon: '💬' },
  { key: 'productivity' as const, label: 'Productivity', icon: '⚡' },
  { key: 'knowledge' as const, label: 'Knowledge', icon: '📚' },
  { key: 'development' as const, label: 'Development & AI', icon: '🤖' },
  { key: 'infrastructure' as const, label: 'Infrastructure', icon: '🛠️' },
];

function Home() {
  return (
    <div className="min-h-screen">
      {/* Header */}
      <header className="bg-white/80 backdrop-blur-md border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-3">
              <div className="flex items-center justify-center w-10 h-10 rounded-xl bg-gradient-to-br from-blue-600 to-indigo-600 text-white font-bold text-lg shadow-md">
                oD
              </div>
              <div>
                <h1 className="text-xl font-bold text-gray-900 leading-tight">openDesk Edu</h1>
                <p className="text-xs text-gray-500 leading-tight">Collaboration Platform</p>
              </div>
            </div>
            <a
              href="https://id.home.opendesk-edu.org/realms/opendesk/protocol/openid-connect/auth?client_id=portal&redirect_uri=https%3A%2F%2Fhome.opendesk-edu.org&response_type=code&scope=openid%20profile%20email"
              className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition-colors shadow-sm"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 16l-4-4m0 0l4-4m-4 4h14m-5-4v8" />
              </svg>
              Login
            </a>
          </div>
        </div>
      </header>

      {/* Hero */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-12 pb-8">
        <div className="text-center">
          <h2 className="text-4xl font-bold text-gray-900 sm:text-5xl">
            Your collaborative workspace
          </h2>
          <p className="mt-4 text-lg text-gray-600 max-w-2xl mx-auto">
            Access all openDesk Edu services from one place. Single Sign-On with your university account,
            integrated tools for teaching, research, and collaboration.
          </p>
          <div className="mt-6 flex items-center justify-center gap-4 text-sm text-gray-500">
            <span className="inline-flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-green-500"></span>
              {services.filter((s) => s.status === 'live').length} services live
            </span>
            <span className="inline-flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-blue-500"></span>
              {services.filter((s) => s.ssoEnabled).length} SSO-enabled
            </span>
          </div>
        </div>
      </div>

      {/* Service Grid */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-16">
        {categories.map((cat) => {
          const filtered = services.filter((s) => s.category === cat.key);
          if (filtered.length === 0) return null;
          return (
            <section key={cat.key} className="mb-10">
              <div className="flex items-center gap-2 mb-4">
                <span className="text-xl">{cat.icon}</span>
                <h3 className="text-lg font-semibold text-gray-800">{cat.label}</h3>
                <span className="text-sm text-gray-400">({filtered.length})</span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                {filtered.map((service) => (
                  <ServiceCard key={service.id} service={service} />
                ))}
              </div>
            </section>
          );
        })}

        {/* Staff & Student Services */}
        <section className="mb-10">
          <div className="flex items-center gap-2 mb-4">
            <span className="text-xl">🎓</span>
            <h3 className="text-lg font-semibold text-gray-800">Staff & Student Services</h3>
            <span className="text-sm text-gray-400">({staffServices.length})</span>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {staffServices.map((service) => (
              <ServiceCard key={service.id} service={service} />
            ))}
          </div>
        </section>
      </div>

      {/* Footer */}
      <footer className="border-t border-gray-200 bg-white/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
            <p className="text-sm text-gray-500">
              openDesk Edu · Powered by{' '}
              <a href="https://scs.community" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">
                SCS
              </a>{' '}
              · Hosted at Philipps-Universität Marburg
            </p>
            <div className="flex items-center gap-4 text-sm text-gray-500">
              <a href="https://id.home.opendesk-edu.org/realms/opendesk/account/" target="_blank" rel="noopener noreferrer" className="hover:text-gray-700">
                Account
              </a>
              <span className="text-gray-300">|</span>
              <a href="https://xwiki.home.opendesk-edu.org" target="_blank" rel="noopener noreferrer" className="hover:text-gray-700">
                Docs
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default Home;
