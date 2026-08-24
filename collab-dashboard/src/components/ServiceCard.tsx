import { ServiceTool } from '../data/tools';

const statusConfig: Record<string, { label: string; color: string; dot: string }> = {
  live: { label: 'Live', color: 'bg-green-100 text-green-700', dot: 'bg-green-500' },
  beta: { label: 'Beta', color: 'bg-yellow-100 text-yellow-700', dot: 'bg-yellow-500' },
  planned: { label: 'Planned', color: 'bg-gray-100 text-gray-500', dot: 'bg-gray-400' },
};

function ServiceCard({ service }: { service: ServiceTool }) {
  const status = statusConfig[service.status];
  return (
    <a
      href={service.launchUrl}
      target="_blank"
      rel="noopener noreferrer"
      className="group block bg-white rounded-2xl border border-gray-200 p-6 hover:border-blue-300 hover:shadow-lg transition-all duration-200"
    >
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-3">
          <span className="text-3xl" role="img" aria-label={service.name}>
            {service.icon}
          </span>
          <div>
            <h4 className="text-base font-semibold text-gray-900 group-hover:text-blue-600 transition-colors">
              {service.name}
            </h4>
            <div className="flex items-center gap-2 mt-0.5">
              <span className={`inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded-full ${status.color}`}>
                <span className={`w-1.5 h-1.5 rounded-full ${status.dot}`}></span>
                {status.label}
              </span>
              {service.ssoEnabled && (
                <span className="inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded-full bg-blue-100 text-blue-700">
                  <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clipRule="evenodd" />
                  </svg>
                  SSO
                </span>
              )}
            </div>
          </div>
        </div>
        <svg
          className="w-5 h-5 text-gray-300 group-hover:text-blue-500 group-hover:translate-x-1 transition-all"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
        </svg>
      </div>
      <p className="text-sm text-gray-600 leading-relaxed">{service.description}</p>
    </a>
  );
}

export default ServiceCard;
