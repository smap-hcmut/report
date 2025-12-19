# Draw.io-like Diagram Tool

## Overview
This project is a web-based drag-and-drop diagramming tool, similar to draw.io, built with Next.js, TypeScript, and modern UI libraries. Its purpose is to provide users with an intuitive platform to create and customize various types of diagrams and charts. The tool aims for a modern, minimalist user interface with professional iconography and alerts, offering both dark and light themes, and supporting English and Vietnamese languages. The long-term vision is to become a comprehensive solution for data analysis workflows, offering advanced features like workflow execution, data transformation, and collaboration.

## User Preferences
- **Ngôn ngữ giao tiếp:** Tiếng Việt
- **Coding Style:** TypeScript strict mode, component-based architecture
- **UI Approach:** Modern, minimalist, professional

## System Architecture

### UI/UX Decisions
The application features a modern, minimalist design with a balanced and professional aesthetic. It includes a sticky top navigation bar ("INT SOLUTION" brand with gradient, navigation links for Overview, Data Center, Workflow, Analyst, active page indicator with gradient animation) and a simple, professional footer. Key UI components like theme and language switchers are integrated seamlessly. Animations are implemented using Framer Motion for smooth transitions and subtle hover effects.

The core of the application is the "Overview Page" which houses the diagramming canvas and a collapsible sidebar for nodes. The sidebar is responsive and features smooth animations, displaying node items in a grid layout. Node items are square icon cards with tooltips and hover effects, draggable onto the canvas.

### Technical Implementations
The application is built using **Next.js** (Pages Router), **TypeScript**, and styled with **Tailwind CSS**. **Lucide React** and **React Icons** provide a comprehensive icon system, while **Framer Motion** handles animations. **next-themes** is used for theme switching (dark/light mode), and **Radix UI** provides accessible UI components like Tooltip, Collapsible, and Dialog. For internationalization, **next-i18next** and **react-i18next** are integrated, supporting English and Vietnamese. Utility functions for class names are managed by `clsx` and `tailwind-merge`.

### Feature Specifications
The application's core functionality revolves around a **React Flow**-based canvas:
- **Drag & Drop Canvas**: Users can drag and drop nodes from a sidebar onto the canvas.
- **Custom Nodes**: Nodes are configurable with various shapes (square, rectangle, circle) and compact sizing.
- **Handles System**: Input, requirement, and output handles are positioned precisely on node borders with distinct shapes (square, diamond, rectangle respectively), theme-colored, and have transparent labels positioned outside the node.
- **Connections**: Smooth, animated dashed Bezier curves with arrow markers and customizable colors.
- **Canvas Features**: Supports zoom in/out, fit view, locking, background dots pattern, and theme-aware styling. Double-clicking a node opens a configuration modal for display name, input/requirement values, and data persistence.
- **Canvas Control Buttons**: "Run" (execute workflow), "Pause" (placeholder), "Save" (download JSON), and "Clear" (remove all elements).
- **Node Types**: A comprehensive system of 32 nodes categorized into 7 groups: Social Media (5), AI (1), Processing (2), Basic (9 - input-only), Output (2), Charts (6), and Action (6). These nodes support complex data analysis workflows.
- **Workflow Save/Load**: Implemented using `localStorage` for auto-saving drafts every second, auto-restoring drafts, and explicitly saving/loading named workflows through a dedicated management page with advanced features (rename, duplicate, export, search).
- **Workflow Management**: Enhanced workflow page with rename (modal dialog), duplicate (copy workflow), export (download JSON), and search/filter capabilities.

### System Design Choices
The project prioritizes a component-based architecture for maintainability and scalability. Strict TypeScript usage ensures type safety. The UI emphasizes a minimalist and professional look, avoiding excessive animations. The decision to use React Flow provides a powerful foundation for node-based diagrams, with extensive customization for nodes, handles, and connections to meet specific design requirements. Storage for workflows is handled client-side using `localStorage` for quick access and persistence.

## External Dependencies
- **Next.js**: Frontend Framework
- **TypeScript**: Language
- **Tailwind CSS**: Styling framework
- **Lucide React**: Icon system
- **React Icons**: Additional icon library (Font Awesome, Material Design, Tabler Icons)
- **Framer Motion**: Animations
- **next-themes**: Theme management (dark/light mode)
- **Radix UI**: UI components (Tooltip, Collapsible, Dialog)
- **clsx**: Utility for conditionally joining class names
- **tailwind-merge**: Utility for merging Tailwind CSS classes
- **next-i18next**: Internationalization for Next.js
- **react-i18next**: React integration for i18n
- **i18next**: Internationalization framework
- **React Flow (reactflow)**: Node-based diagram library

## Recent Changes

### Latest Update (13/10/2025) - Part 4
- ✅ **Phase 2: Function Selector for Social Media Nodes**: Dynamic action selection system
  - **Function Catalog**: Defined functions for all 5 Social Media platforms
    - Facebook: Post, Comment, Like, Share, Get Posts (5 functions)
    - Instagram: Post, Comment, Like, Get Posts (4 functions)
    - TikTok: Post Video, Comment, Like, Get Videos (4 functions)
    - LinkedIn: Post, Comment, Like, Share, Get Posts (5 functions)
    - Twitter: Tweet, Reply, Retweet, Like, Get Tweets (5 functions)
  - **Function Selector UI**: Dropdown in config modal for Social Media nodes
  - **Dynamic Parameters**: Config fields change based on selected function
  - **Field Types**: Support text, textarea, select, number inputs
  - **Validation**: Enforces function selection and required field completion
  - **Data Persistence**: selectedFunction and functionFields saved with node
  - **Smart UI**: Hides Input/Requirement sections for Social Media nodes (replaced by Function Parameters)

### Latest Update (13/10/2025) - Part 3
- ✅ **Auto-Populate Config Modal**: Config fields automatically show connected node data
  - **Smart Detection**: Modal detects connected edges and displays source node data
  - **Input/Requirement Auto-Fill**: Fields auto-populate with data from connected nodes
  - **Visual Indicators**: Shows "(from [NodeName])" label for connected data
  - **Readonly Connected Fields**: Connected data displayed as readonly with distinct styling
  - **Editable Manual Fields**: Unconnected fields remain editable for manual input
  - **Real-time Updates**: Data refreshes when connections change

### Latest Update (13/10/2025) - Part 2
- ✅ **Workflow Execution Engine (Phase 1)**: Fully functional execution system
  - **Topological Sort**: Automatically determines correct node execution order, detects cycles
  - **Data Validation**: Validates input data types against node config before execution
  - **Real-time Visual Feedback**: Edge colors change during execution
    - Blue (#3b82f6): Currently running with animation
    - Green (#10b981): Successfully completed
    - Red (#ef4444): Error occurred
  - **Data Flow**: Passes data between nodes through connections
  - **Error Handling**: Comprehensive error messages for validation failures, missing inputs
  - **Run Button**: Executes entire workflow with visual progress

### Latest Update (13/10/2025) - Part 1
- ✅ **Enhanced Node Configuration Modal**: Major upgrade for data analyst workflows
  - **Output Data Display**: All nodes with output handles now show output data in config modal
  - **Basic Nodes Input**: Basic nodes (Text, Integer, JSON, CSV, etc.) have "Input Data" section to enter data directly
  - **Data Persistence**: outputValues are saved with node data and persist through workflows
  - **Smart UI**: Modal adapts based on node type (Basic vs Processing vs Output nodes)
  - **Monospace textarea**: Better data visualization with monospace font for JSON/CSV data
- ✅ **Enhanced Workflow Page**: 
  - Rename workflow (modal dialog with validation)
  - Duplicate workflow (creates copy with "(Copy)" suffix)
  - Export workflow (download as JSON with sanitized filename)
  - Search/Filter (live filtering by workflow name, case-insensitive)
- ✅ **Added Time Range Node**: New Basic node with calendar icon for date range selection (From/To outputs)
- ✅ **Total nodes**: 32 (Basic group now has 9 nodes)
- ✅ **Fixed Critical Bug**: Load workflow with route guard (reloads only when navigating to /overview)