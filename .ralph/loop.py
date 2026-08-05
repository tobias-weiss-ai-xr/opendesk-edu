#!/usr/bin/env python3
"""
Ralph Loop Runner: HRZ Deployment Continuous Improvement

This script executes the Ralph loop defined in config.yaml.
It runs the configured tasks, collects results, and generates reports.
"""
import os
import sys
import json
import yaml
import subprocess
import datetime
import logging
import smtplib
from pathlib import Path
from email.mime.text import MIMEText
from typing import Dict, List, Any

log_dir = Path('/var/log/ralph')
try:
    log_dir.mkdir(parents=True, exist_ok=True)
    log_handlers = [
        logging.FileHandler(log_dir / 'loop.log', mode='a'),
        logging.StreamHandler()
    ]
except (PermissionError, OSError):
    log_handlers = [logging.StreamHandler()]

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=log_handlers
)
logger = logging.getLogger('ralph-loop')


class RalphLoop:
    """Ralph loop executor for HRZ deployment continuous improvement."""
    
    def __init__(self, config_path: str = '.ralph/config.yaml'):
        self.config_path = Path(config_path)
        self.config = self._load_config()
        self.report_dir = Path(self.config['reporting']['output_dir'])
        try:
            self.report_dir.mkdir(parents=True, exist_ok=True)
        except (PermissionError, OSError):
            self.report_dir = Path('.ralph/reports')
            self.report_dir.mkdir(parents=True, exist_ok=True)
        self.iteration = 0
        self.results = []
    
    def _load_config(self) -> Dict[str, Any]:
        """Load Ralph loop configuration."""
        if not self.config_path.exists():
            logger.error(f"Config not found: {self.config_path}")
            sys.exit(1)
        with open(self.config_path) as f:
            return yaml.safe_load(f)
    
    def _run_task(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a single task and return results."""
        task_id = task['id']
        description = task['description']
        command = task['command']
        
        logger.info(f"Running task: {task_id} - {description}")
        
        start_time = datetime.datetime.now()
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=300,
                executable='/bin/bash'
            )
            output = result.stdout + result.stderr
            success = result.returncode == 0
        except subprocess.TimeoutExpired:
            output = "Task timed out after 300 seconds"
            success = False
        except Exception as e:
            output = f"Error: {str(e)}"
            success = False
        
        end_time = datetime.datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        return {
            'task_id': task_id,
            'description': description,
            'success': success,
            'output': output[:2000],  # Truncate to 2000 chars
            'duration': duration,
            'timestamp': start_time.isoformat()
        }
    
    def _check_thresholds(self, output: str) -> bool:
        """Check if output meets threshold requirements."""
        for line in output.split('\n'):
            if 'Disk > 80%' in line or 'Memory > 90%' in line:
                return False
        return True
    
    def _generate_recommendations(self, results: List[Dict]) -> List[str]:
        """Generate improvement recommendations based on results."""
        recommendations = []
        for result in results:
            if not result['success']:
                recommendations.append(
                    f"⚠️ Fix {result['task_id']}: {result['description']}"
                )
            if 'ERROR' in result['output'] or 'FATAL' in result['output']:
                recommendations.append(
                    f"🔍 Investigate {result['task_id']}: Errors found in output"
                )
            if 'WARNING' in result['output']:
                recommendations.append(
                    f"⚡ Review {result['task_id']}: Warnings detected"
                )
        if not recommendations:
            recommendations.append("✅ All tasks passed - system is healthy")
        return recommendations
    
    def _save_report(self, results: List[Dict], recommendations: List[str]):
        """Save iteration report."""
        timestamp = datetime.datetime.now()
        report = {
            'iteration': self.iteration,
            'timestamp': timestamp.isoformat(),
            'loop_name': self.config['loop']['name'],
            'total_tasks': len(results),
            'successful': sum(1 for r in results if r['success']),
            'failed': sum(1 for r in results if not r['success']),
            'total_duration': sum(r['duration'] for r in results),
            'results': results,
            'recommendations': recommendations
        }
        
        report_file = self.report_dir / f"iteration-{timestamp.strftime('%Y%m%d-%H%M%S')}.json"
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        md_file = self.report_dir / f"iteration-{timestamp.strftime('%Y%m%d-%H%M%S')}.md"
        with open(md_file, 'w') as f:
            f.write(f"# Ralph Loop Iteration {self.iteration}\n\n")
            f.write(f"**Timestamp**: {timestamp.isoformat()}\n\n")
            f.write(f"**Total Tasks**: {report['total_tasks']}\n")
            f.write(f"**Successful**: {report['successful']}\n")
            f.write(f"**Failed**: {report['failed']}\n")
            f.write(f"**Duration**: {report['total_duration']:.2f}s\n\n")
            f.write("## Results\n\n")
            for r in results:
                status = "✅" if r['success'] else "❌"
                f.write(f"### {status} {r['task_id']}\n")
                f.write(f"**Description**: {r['description']}\n")
                f.write(f"**Duration**: {r['duration']:.2f}s\n\n")
                f.write("```\n")
                f.write(r['output'][:500])
                f.write("\n```\n\n")
            f.write("## Recommendations\n\n")
            for rec in recommendations:
                f.write(f"- {rec}\n")
        
        logger.info(f"Report saved: {report_file}")
        return report_file, md_file
    
    def run_iteration(self) -> bool:
        """Run a single iteration of the Ralph loop."""
        self.iteration += 1
        logger.info(f"Starting Ralph loop iteration {self.iteration}")
        
        results = []
        for area in self.config['focus_areas']:
            logger.info(f"Focus area: {area['name']}")
            for task in area['tasks']:
                result = self._run_task(task)
                results.append(result)
                if result['success']:
                    logger.info(f"  ✅ {result['task_id']} passed")
                else:
                    logger.warning(f"  ❌ {result['task_id']} failed")
        
        recommendations = self._generate_recommendations(results)
        json_report, md_report = self._save_report(results, recommendations)
        
        failed = sum(1 for r in results if not r['success'])
        return failed == 0
    
    def run(self):
        """Run the Ralph loop continuously."""
        max_iter = self.config['loop'].get('max_iterations', 1)
        logger.info(f"Starting Ralph loop: max {max_iter} iterations")
        
        for i in range(max_iter):
            try:
                success = self.run_iteration()
                if not success and self.config.get('safety', {}).get('require_confirmation_for_destructive', False):
                    logger.warning("Iteration had failures - manual review recommended")
            except KeyboardInterrupt:
                logger.info("Ralph loop stopped by user")
                break
            except Exception as e:
                logger.error(f"Error in iteration {i+1}: {e}")
        
        logger.info(f"Ralph loop completed after {self.iteration} iterations")


def main():
    if len(sys.argv) > 1:
        config = sys.argv[1]
    else:
        config = '.ralph/config.yaml'
    
    loop = RalphLoop(config)
    loop.run()


if __name__ == '__main__':
    main()
