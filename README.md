# maze_solver

A new Flutter project.# Maze Solver

Maze Solver is a Flutter application that visually demonstrates maze-solving algorithms using an interactive grid interface. Watch the app in action as it uses pathfinding techniques such as Dijkstra, Depth-First Search (DFS), and Breadth-First Search (BFS) to find the optimal path through a maze.

## Features

- **Interactive Maze Grid:**  
  A 20x20 grid where you can manually toggle obstacles by tapping cells. The start node (top-left) and end node (bottom-right) are clearly marked.

- **Multiple Pathfinding Algorithms:**  
  Choose from three algorithms:
  - **Dijkstra:** Finds the shortest path using a weighted approach.
  - **DFS (Depth-First Search):** Explores as far as possible along each branch.
  - **BFS (Breadth-First Search):** Explores the maze level by level.

- **Animated Visualization:**  
  Real-time animation shows nodes being visited and highlights the final path.

- **Optimal Display Mode:**  
  Uses `flutter_displaymode` to set the best available refresh rate for smooth animations.

- **Persistent Preferences:**  
  Utilizes `shared_preferences` to store user settings (such as refresh rate preferences).

## Tech Stack

- **Language & Framework:**  
  - [Flutter](https://flutter.dev)  
  - [Dart](https://dart.dev)

- **Key Libraries:**  
  - [cupertino_icons](https://pub.dev/packages/cupertino_icons): Provides iOS-style icons.  
  - [flutter_displaymode](https://pub.dev/packages/flutter_displaymode): Optimizes display refresh rates.  
  - [shared_preferences](https://pub.dev/packages/shared_preferences): Manages local storage for user preferences.  
  - [collection](https://pub.dev/packages/collection): Supplies advanced data structures like PriorityQueue used in Dijkstra's algorithm.

## Installation Guide

### Prerequisites

- **Flutter SDK:**  
  Ensure you have Flutter installed. Refer to [flutter.dev](https://flutter.dev) for setup instructions.

- **Git:**  
  For cloning the repository.

### Setup Steps

1. **Clone the Repository:**
   ```bash
   git clone https://your-repo-url/maze_solver.git
   cd maze_solver


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
