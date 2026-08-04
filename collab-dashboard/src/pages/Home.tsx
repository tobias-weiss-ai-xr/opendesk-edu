import CardGrid from '../components/CardGrid';
import { tools } from '../data/tools';

function Home() {
  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <header className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Collab Services</h1>
        <p className="text-gray-600 mt-2">
          Interactive computing tools for openDesk Edu — notebooks, LaTeX, AI, terminals, and more.
        </p>
      </header>
      <CardGrid tools={tools} />
    </div>
  );
}

export default Home;
