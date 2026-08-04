import { CollabTool } from '../data/tools';
import ToolCard from './ToolCard';

const categories = [
  { key: 'computing' as const, label: 'Computing' },
  { key: 'editing' as const, label: 'Editing & Authoring' },
  { key: 'ai' as const, label: 'AI & Assistants' },
  { key: 'visualization' as const, label: 'Visualization' },
  { key: 'teaching' as const, label: 'Teaching' },
  { key: 'infrastructure' as const, label: 'Infrastructure' },
];

function CardGrid({ tools }: { tools: CollabTool[] }) {
  return (
    <div className="space-y-8">
      {categories.map((cat) => {
        const filtered = tools.filter((t) => t.category === cat.key);
        if (filtered.length === 0) return null;
        return (
          <section key={cat.key}>
            <h2 className="text-xl font-bold text-gray-800 mb-4">{cat.label}</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
              {filtered.map((tool) => (
                <ToolCard key={tool.id} tool={tool} />
              ))}
            </div>
          </section>
        );
      })}
    </div>
  );
}

export default CardGrid;
