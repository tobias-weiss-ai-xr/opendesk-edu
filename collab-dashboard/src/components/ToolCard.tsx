import { CollabTool } from '../data/tools';

const statusColors: Record<string, string> = {
  stable: 'bg-green-100 text-green-800',
  beta: 'bg-yellow-100 text-yellow-800',
  planned: 'bg-gray-100 text-gray-600',
};

function ToolCard({ tool }: { tool: CollabTool }) {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between mb-3">
        <h3 className="text-lg font-semibold text-gray-900">{tool.name}</h3>
        <span className={`text-xs font-medium px-2 py-1 rounded-full ${statusColors[tool.status]}`}>
          {tool.status}
        </span>
      </div>
      <p className="text-sm text-gray-600 mb-2">{tool.coCalcFeature}</p>
      <p className="text-sm text-gray-500 mb-4">{tool.description}</p>
      <div className="flex gap-2">
        {tool.launchUrl && (
          <a
            href={tool.launchUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm px-3 py-1.5 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
          >
            Launch
          </a>
        )}
        <a
          href={tool.upstreamUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="text-sm px-3 py-1.5 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 transition-colors"
        >
          Learn More
        </a>
      </div>
    </div>
  );
}

export default ToolCard;
