import { useTranslation } from 'react-i18next';
import { LayoutGrid, PieChart, Target, Users2 } from 'lucide-react';

export default function ScreenshotsSection() {
  const { t } = useTranslation();

  const screens = [
    {
      title: t('screenshots.screen1'),
      icon: <LayoutGrid className="w-5 h-5 text-primary-soft" />,
      color: "from-primary/20 to-primary/5",
      desc: "Overview of your financial wellness."
    },
    {
      title: t('screenshots.screen2'),
      icon: <PieChart className="w-5 h-5 text-lemon" />,
      color: "from-lemon/20 to-lemon/5",
      desc: "Detailed charts representing your monthly limits."
    },
    {
      title: t('screenshots.screen3'),
      icon: <Target className="w-5 h-5 text-ruby" />,
      color: "from-ruby/20 to-ruby/5",
      desc: "Goal targets like a new phone or laptop tracker."
    },
    {
      title: t('screenshots.screen4'),
      icon: <Users2 className="w-5 h-5 text-magenta" />,
      color: "from-magenta/20 to-magenta/5",
      desc: "Shared logs with partner invitations."
    }
  ];

  return (
    <section className="py-24 bg-canvas-soft dark:bg-brand-dark-900/60 transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="font-display-xl text-ink dark:text-canvas mb-4 text-3xl sm:text-4xl text-center">
            {t('screenshots.title')}
          </h2>
          <div className="w-16 h-1 bg-primary dark:bg-primary-soft mx-auto rounded-full"></div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
          {screens.map((screen, idx) => (
            <div 
              key={idx}
              className="bg-canvas dark:bg-[#0d0e26] border border-hairline dark:border-hairline/10 rounded-[20px] overflow-hidden shadow-level-1 transition-all duration-300 hover:-translate-y-1 hover:shadow-level-2"
            >
              {/* Mock Screen Header */}
              <div className={`h-40 bg-gradient-to-br ${screen.color} flex items-center justify-center relative p-6 border-b border-hairline/40 dark:border-hairline/10`}>
                <div className="bg-brand-dark-900 text-white rounded-[12px] p-4 shadow-md flex items-center gap-3">
                  {screen.icon}
                  <span className="font-semibold text-xs">{screen.title}</span>
                </div>
              </div>

              {/* Info */}
              <div className="p-6">
                <h3 className="font-bold text-sm text-ink dark:text-canvas mb-2">{screen.title}</h3>
                <p className="text-xs text-ink-mute dark:text-canvas-soft/80 leading-relaxed font-light">
                  {screen.desc}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
