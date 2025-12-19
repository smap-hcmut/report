# SEO Controller

A comprehensive SEO monitoring and trend analysis platform built with Next.js, TypeScript, and React.

## Features

- **Real-time Dashboard** - Monitor SEO metrics in real-time with WebSocket integration
- **Trend Analysis** - Analyze trending topics, hashtags, and posts
- **Custom Reports** - Generate and export customizable SEO reports
- **Workflow Automation** - Visual workflow builder with drag-and-drop interface
- **Multi-language Support** - i18n integration for internationalization
- **Responsive Design** - Mobile-first design with Tailwind CSS
- **Dark Mode** - Built-in theme switching

## Tech Stack

- **Framework:** Next.js 15.2.3
- **Language:** TypeScript 5.8.2
- **UI Library:** React 19.0.0
- **Styling:** Tailwind CSS 3.4.18
- **Charts:** Chart.js, Recharts, React Flow
- **State Management:** React Context API
- **Internationalization:** next-i18next

## Quick Start

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Open browser
# http://localhost:5000
```

For detailed setup instructions, see [SETUP.md](SETUP.md)

## Project Structure

```
SEO-Controller/
├── components/          # React components
│   ├── dashboard/      # Dashboard components
│   ├── reports/        # Report components
│   ├── trend/          # Trend analysis components
│   └── FlowCanvas.tsx  # Workflow builder
├── pages/              # Next.js pages
│   ├── dashboard.tsx   # Dashboard page
│   ├── trend-analysis.tsx
│   ├── workflow.tsx
│   └── index.tsx
├── contexts/           # React contexts
├── hooks/              # Custom hooks
├── services/           # API services
├── lib/                # Utilities
├── config/             # Configuration
└── public/             # Static assets
```

## Available Scripts

```bash
npm run dev      # Start development server (port 5000)
npm run build    # Build for production
npm start        # Start production server
npm run lint     # Run ESLint
```

## Docker Support

Build and run with Docker:

```bash
# Build image
docker-compose build

# Run container
docker-compose up

# Run in background
docker-compose up -d
```

See [docker-build.md](docker-build.md) for more details.

## Environment Variables

Copy `.env.example` to `.env` and configure:

```env
NODE_ENV=development
PORT=5000
HOSTNAME=0.0.0.0

# API Configuration
NEXT_PUBLIC_HOSTNAME=https://smap-api.tantai.dev

# WebSocket Configuration
NEXT_PUBLIC_WS_URL=wss://smap-api.tantai.dev/ws
```

### Key Environment Variables

- `NEXT_PUBLIC_HOSTNAME` - Base URL for API endpoints
- `NEXT_PUBLIC_WS_URL` - WebSocket URL for real-time project and job status updates
  - Production: `wss://smap-api.tantai.dev/ws`
  - Development: `ws://localhost:8081/ws`
  - Connection patterns: `?projectId={id}` or `?jobId={id}`
- `PORT` - Port for the Next.js development server (default: 5000)

## Documentation

- [SETUP.md](SETUP.md) - Complete setup guide for new machines
- [docker-build.md](docker-build.md) - Docker build and deployment guide
- [CHART_DATA_STRUCTURES.md](CHART_DATA_STRUCTURES.md) - Chart data structures

## Key Features

### Real-time Dashboard

- Live metrics updates via WebSocket
- Customizable metric cards
- Interactive charts and visualizations
- Project selector and time range filters

### Trend Analysis

- Trending topics discovery
- Hashtag tracking
- Post analysis
- Sentiment analysis
- Competitor monitoring

### Report Generation

- Custom report builder
- Multiple templates
- Data source selection
- Export functionality

### Workflow Automation

- Visual workflow designer
- Node-based interface
- Pre-built templates
- Custom node configuration

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Contributing

1. Create a new branch: `git checkout -b feature/your-feature`
2. Make your changes
3. Commit: `git commit -m "feat: add your feature"`
4. Push: `git push origin feature/your-feature`
5. Create a Pull Request

## Troubleshooting

See [SETUP.md - Troubleshooting](SETUP.md#troubleshooting-xử-lý-lỗi) section for common issues and solutions.

## License

Private - All rights reserved

## Support

For issues and questions:

- Check [SETUP.md](SETUP.md) documentation
- Review existing GitHub issues
- Contact the development team

---

**Built with ❤️ using Next.js and TypeScript**
