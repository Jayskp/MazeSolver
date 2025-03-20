import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:collection' show Queue;
import 'package:collection/collection.dart';

class Node {
  final int row, col;
  bool isObstacle, isVisited, isPath;
  double distance; // Represents the "g-cost" in pathfinding.
  Node? previous;

  Node({
    required this.row,
    required this.col,
    this.isObstacle = false,
    this.isVisited = false,
    this.isPath = false,
    this.distance = double.infinity,
    this.previous,
  });

  void reset({bool keepObstacles = true}) {
    isVisited = false;
    isPath = false;
    distance = double.infinity;
    previous = null;
    if (!keepObstacles) isObstacle = false;
  }
}

class MazeSolverScreen extends StatefulWidget {
  const MazeSolverScreen({super.key});

  @override
  _MazeSolverScreenState createState() => _MazeSolverScreenState();
}

class _MazeSolverScreenState extends State<MazeSolverScreen>
    with SingleTickerProviderStateMixin {
  int gridSize = 20; // Default grid size (20 x 20)
  late List<List<Node>> grid;
  late Node startNode, endNode;
  bool isRunning = false;

  late AnimationController _controller;
  late Animation<double> _animation;

  // List of algorithms (including A* as an additional DAA functionality)
  final List<String> algorithms = ['Dijkstra', 'DFS', 'BFS', 'A*'];
  String selectedAlgorithm = 'Dijkstra';

  static const Duration visitedAnimDuration = Duration(milliseconds: 20);
  static const Duration pathAnimDuration = Duration(milliseconds: 30);

  // Color definitions
  final Color backgroundColor = const Color(0xFF1E1E2C);
  final Color gridBackgroundColor = const Color(0xFF2D2D3A);
  final Color startColor = const Color(0xFF4CAF50);
  final Color endColor = const Color(0xFFF44336);
  final Color pathColor = const Color(0xFFFFEB3B);
  final Color obstacleColor =  Colors.white;
  final Color visitedColor = const Color(0xFF64B5F6);
  final Color emptyColor = const Color(0xFF3F3F5A);
  final Color buttonColor = const Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _initGrid();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Initializes the grid based on the current gridSize.
  void _initGrid() {
    grid = List.generate(
      gridSize,
          (r) => List.generate(gridSize, (c) => Node(row: r, col: c)),
    );
    startNode = grid[0][0];
    endNode = grid[gridSize - 1][gridSize - 1];
    startNode.distance = 0;
  }

  /// Resets grid nodes while optionally preserving obstacles.
  void _resetGrid({bool keepObstacles = true}) {
    setState(() {
      for (var row in grid) {
        for (var node in row) {
          node.reset(keepObstacles: keepObstacles);
        }
      }
      startNode.distance = 0;
    });
  }

  /// Returns valid neighbors (up, down, left, right) for a given node.
  List<Node> _getNeighbors(Node node) {
    final r = node.row, c = node.col;
    List<Node> neighbors = [];
    if (r > 0) neighbors.add(grid[r - 1][c]);
    if (r < gridSize - 1) neighbors.add(grid[r + 1][c]);
    if (c > 0) neighbors.add(grid[r][c - 1]);
    if (c < gridSize - 1) neighbors.add(grid[r][c + 1]);
    return neighbors;
  }

  /// Animates the final path from the end node back to the start.
  Future<void> _animatePath() async {
    List<Node> path = [];
    Node? current = endNode;
    if (current.previous == null) return;
    while (current != null) {
      path.add(current);
      current = current.previous;
    }
    for (int i = path.length - 1; i >= 0; i--) {
      setState(() {
        path[i].isPath = true;
      });
      await Future.delayed(pathAnimDuration);
    }
  }

  /// Dijkstra's algorithm implementation.
  Future<void> _runDijkstra() async {
    setState(() {
      isRunning = true;
    });
    _resetGrid(keepObstacles: true);
    startNode.distance = 0;

    // Use a priority queue to get the unvisited node with the smallest distance.
    final unvisitedQueue =
    PriorityQueue<Node>((a, b) => a.distance.compareTo(b.distance));

    for (var row in grid) {
      for (var node in row) {
        unvisitedQueue.add(node);
      }
    }

    while (unvisitedQueue.isNotEmpty) {
      final current = unvisitedQueue.removeFirst();

      if (current.isVisited) continue;
      if (current.distance == double.infinity) {
        _showNoPathFound();
        break;
      }

      setState(() {
        current.isVisited = true;
      });
      await Future.delayed(visitedAnimDuration);

      if (current == endNode) {
        await _animatePath();
        setState(() {
          isRunning = false;
        });
        return;
      }

      for (final neighbor in _getNeighbors(current)) {
        if (neighbor.isVisited || neighbor.isObstacle) continue;

        final alt = current.distance + 1; // Constant cost for adjacent nodes.
        if (alt < neighbor.distance) {
          setState(() {
            neighbor.distance = alt;
            neighbor.previous = current;
          });
          unvisitedQueue.add(neighbor);
        }
      }
    }
    setState(() {
      isRunning = false;
    });
  }

  /// Depth-first search algorithm.
  Future<void> _runDFS() async {
    setState(() {
      isRunning = true;
    });
    _resetGrid(keepObstacles: true);
    final stack = <Node>[startNode];
    final visited = <Node>{};

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (visited.contains(current)) continue;
      visited.add(current);
      setState(() {
        current.isVisited = true;
      });
      await Future.delayed(visitedAnimDuration);

      if (current == endNode) {
        await _animatePath();
        break;
      }
      for (var neighbor in _getNeighbors(current)) {
        if (!visited.contains(neighbor) && !neighbor.isObstacle) {
          neighbor.previous = current;
          stack.add(neighbor);
        }
      }
    }
    setState(() {
      isRunning = false;
    });
  }

  /// Breadth-first search algorithm.
  Future<void> _runBFS() async {
    setState(() {
      isRunning = true;
    });
    _resetGrid(keepObstacles: true);
    final queue = Queue<Node>();
    queue.add(startNode);
    startNode.isVisited = true;

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      setState(() {
        current.isVisited = true;
      });
      await Future.delayed(visitedAnimDuration);

      if (current == endNode) {
        await _animatePath();
        break;
      }
      for (var neighbor in _getNeighbors(current)) {
        if (!neighbor.isVisited && !neighbor.isObstacle) {
          setState(() {
            neighbor.isVisited = true;
            neighbor.previous = current;
            neighbor.distance = current.distance + 1;
          });
          queue.add(neighbor);
        }
      }
    }
    setState(() {
      isRunning = false;
    });
  }

  /// Heuristic function for A* (using Manhattan distance).

  /// A* algorithm implementation.

  /// Runs the algorithm selected by the user.
  Future<void> _runAlgorithm() async {
    switch (selectedAlgorithm) {
      case 'Dijkstra':
        await _runDijkstra();
        break;
      case 'DFS':
        await _runDFS();
        break;
      case 'BFS':
        await _runBFS();
        break;
    }
  }

  /// Displays a snackbar when no path is found.
  void _showNoPathFound() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'No path found! Try removing some obstacles.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Builds a legend item (colored box with a label).
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  /// Builds a simplified button.
  Widget _buildButton(String label, IconData icon, VoidCallback? onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  /// Builds the grid size dropdown to select the grid dimensions.
  Widget _buildGridSizeDropdown() {
    List<int> gridSizes = [10, 15, 20, 25, 30];
    return Row(
      children: [
        const Text(
          'Grid Size:',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: gridSize,
          dropdownColor: gridBackgroundColor,
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white),
          onChanged: isRunning
              ? null
              : (newSize) {
            if (newSize != null) {
              setState(() {
                gridSize = newSize;
                _initGrid(); // Reinitialize grid with the new size.
              });
            }
          },
          items: gridSizes.map((size) {
            return DropdownMenuItem<int>(
              value: size,
              child: Text('$size x $size'),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Maze Solver',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: FadeTransition(
        opacity: _animation,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Algorithm and Grid Size selectors with a status indicator.
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: gridBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Algorithm:',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: selectedAlgorithm,
                          dropdownColor: gridBackgroundColor,
                          underline: Container(),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.white),
                          style: const TextStyle(color: Colors.white),
                          onChanged: isRunning
                              ? null
                              : (newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedAlgorithm = newValue;
                              });
                            }
                          },
                          items: algorithms.map((value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: 16),
                        _buildGridSizeDropdown(),
                      ],
                    ),
                    ]
                ),
              ),// Status indicator.
              const SizedBox(height: 16),
              // Legend.
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: gridBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem('Start', startColor),
                    _buildLegendItem('End', endColor),
                    _buildLegendItem('Wall', obstacleColor),
                    _buildLegendItem('Path', pathColor),
                    _buildLegendItem('Visited', visitedColor),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Grid display.
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: gridBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(4),
                          physics:
                          const NeverScrollableScrollPhysics(),
                          gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridSize,
                            childAspectRatio: 1,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                          ),
                          itemCount: gridSize * gridSize,
                          itemBuilder: (context, index) {
                            final row = index ~/ gridSize;
                            final col = index % gridSize;
                            final node = grid[row][col];
                            Color color;
                            if (node == startNode) {
                              color = startColor;
                            } else if (node == endNode) {
                              color = endColor;
                            } else if (node.isPath) {
                              color = pathColor;
                            } else if (node.isObstacle) {
                              color = obstacleColor;
                            } else if (node.isVisited) {
                              color = visitedColor;
                            } else {
                              color = emptyColor;
                            }
                            return GestureDetector(
                              onTap: () {
                                if (!isRunning &&
                                    node != startNode &&
                                    node != endNode) {
                                  setState(() {
                                    node.isObstacle = !node.isObstacle;
                                  });
                                }
                              },
                              child: AnimatedContainer(
                                duration:
                                const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius:
                                  BorderRadius.circular(4),
                                  boxShadow: node.isObstacle
                                      ? [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.2),
                                      blurRadius: 2,
                                      offset:
                                      const Offset(0, 1),
                                    ),
                                  ]
                                      : null,
                                ),
                                child: node == startNode
                                    ? const Icon(Icons.play_arrow,
                                    color: Colors.white, size: 14)
                                    : node == endNode
                                    ? const Icon(Icons.flag,
                                    color: Colors.white,
                                    size: 14)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Control buttons.
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceAround,
                children: [
                  _buildButton('Start', Icons.play_arrow,
                      isRunning ? null : _runAlgorithm),
                  _buildButton('Reset Path', Icons.refresh,
                      isRunning ? null : () => _resetGrid(keepObstacles: true)),
                  _buildButton('Clear All', Icons.delete_outline,
                      isRunning ? null : () => _resetGrid(keepObstacles: false)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
