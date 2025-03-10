import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:collection';

// Model class for each cell/node in the grid.
class Node {
  final int row;
  final int col;
  bool isObstacle;
  bool isVisited;
  bool isPath;
  double distance;
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

  // Reset node state but keep obstacle status
  void reset({bool keepObstacles = true}) {
    isVisited = false;
    isPath = false;
    distance = double.infinity;
    previous = null;
    if (!keepObstacles) {
      isObstacle = false;
    }
  }
}

class MazeSolverScreen extends StatefulWidget {
  const MazeSolverScreen({super.key});

  @override
  State<MazeSolverScreen> createState() => _MazeSolverScreenState();
}

class _MazeSolverScreenState extends State<MazeSolverScreen>
    with SingleTickerProviderStateMixin {
  static const int numRows = 20;
  static const int numCols = 20;
  late List<List<Node>> grid;
  late Node startNode;
  late Node endNode;
  bool isRunning = false;

  // Animation controller for UI transitions
  late AnimationController _controller;
  late Animation<double> _animation;

  // Define algorithm options
  final List<String> algorithms = ['Dijkstra', 'DFS', 'BFS'];
  String selectedAlgorithm = 'Dijkstra';

  // Animation durations
  static const Duration visitedAnimDuration = Duration(milliseconds: 20);
  static const Duration pathAnimDuration = Duration(milliseconds: 30);

  // UI Theme colors
  final Color backgroundColor = const Color(0xFF1E1E2C);
  final Color gridBackgroundColor = const Color(0xFF2D2D3A);
  final Color startColor = const Color(0xFF4CAF50);
  final Color endColor = const Color(0xFFF44336);
  final Color pathColor = const Color(0xFFFFEB3B);
  final Color obstacleColor = const Color(0xFF424242);
  final Color visitedColor = const Color(0xFF64B5F6);
  final Color emptyColor = const Color(0xFF3F3F5A);
  final Color buttonColor = const Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    initGrid();

    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Initialize the grid and set the start and end nodes.
  void initGrid() {
    grid = List.generate(numRows, (r) {
      return List.generate(numCols, (c) {
        return Node(row: r, col: c);
      });
    });
    startNode = grid[0][0];
    endNode = grid[numRows - 1][numCols - 1];
    startNode.distance = 0;
  }

  // Resets the grid to the initial state.
  void resetGrid({bool keepObstacles = true}) {
    setState(() {
      for (var row in grid) {
        for (var node in row) {
          node.reset(keepObstacles: keepObstacles);
        }
      }
      startNode.distance = 0;
    });
  }

  // Returns valid neighbors (up, down, left, right) for a given node.
  List<Node> getNeighbors(Node node) {
    final int r = node.row;
    final int c = node.col;

    // Check all 4 directions
    return [
      if (r > 0) grid[r - 1][c], // Up
      if (r < numRows - 1) grid[r + 1][c], // Down
      if (c > 0) grid[r][c - 1], // Left
      if (c < numCols - 1) grid[r][c + 1], // Right
    ];
  }

  // Animates the final path by tracing back from the end node.
  Future<void> animatePath() async {
    Node? current = endNode;
    // If no path exists, current.previous will be null.
    if (current.previous == null) return;

    List<Node> path = [];
    while (current != null) {
      path.add(current);
      current = current.previous;
    }

    // Animate in reverse order (from start to end)
    for (int i = path.length - 1; i >= 0; i--) {
      setState(() {
        path[i].isPath = true;
      });
      await Future.delayed(pathAnimDuration);
    }
  }

  // Runs Dijkstra's algorithm with animation.
  Future<void> runDijkstra() async {
    setState(() {
      isRunning = true;
    });

    // Reset grid before starting
    resetGrid(keepObstacles: true);
    startNode.distance = 0;

    // Use a priority queue for better performance
    final unvisitedQueue =
        HeapPriorityQueue<Node>((a, b) => a.distance.compareTo(b.distance));

    // Add all nodes to queue
    for (var row in grid) {
      for (var node in row) {
        unvisitedQueue.add(node);
      }
    }

    while (unvisitedQueue.isNotEmpty) {
      Node current = unvisitedQueue.removeFirst();

      // Skip already visited nodes
      if (current.isVisited) continue;

      // If the smallest distance is infinity, no path is possible.
      if (current.distance == double.infinity) break;

      // Mark the node as visited and update the UI.
      setState(() {
        current.isVisited = true;
      });
      await Future.delayed(visitedAnimDuration);

      // If we've reached the end node, animate the final path.
      if (current == endNode) {
        await animatePath();
        setState(() {
          isRunning = false;
        });
        return;
      }

      // Update each neighbor's distance.
      for (Node neighbor in getNeighbors(current)) {
        if (neighbor.isVisited || neighbor.isObstacle) continue;
        double alt = current.distance + 1; // Edge weight is 1
        if (alt < neighbor.distance) {
          setState(() {
            neighbor.distance = alt;
            neighbor.previous = current;
          });

          // Re-add to queue to update position based on new distance
          unvisitedQueue.add(neighbor);
        }
      }
    }

    setState(() {
      isRunning = false;
    });
  }

  // DFS algorithm (replacing A*)
  Future<void> runDFS() async {
    setState(() {
      isRunning = true;
    });

    // Reset grid before starting
    resetGrid(keepObstacles: true);

    // Use a stack for DFS
    final stack = <Node>[];
    stack.add(startNode);

    // Keep track of visited nodes
    final Set<Node> visited = {};

    bool foundPath = false;

    while (stack.isNotEmpty && !foundPath) {
      Node current = stack.removeLast();

      // Skip if already visited
      if (visited.contains(current)) continue;

      // Mark as visited
      visited.add(current);
      setState(() {
        current.isVisited = true;
      });
      await Future.delayed(visitedAnimDuration);

      // Check if we reached the end
      if (current == endNode) {
        foundPath = true;
        await animatePath();
        break;
      }

      // Add unvisited neighbors to stack
      for (Node neighbor in getNeighbors(current)) {
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

  // BFS algorithm
  Future<void> runBFS() async {
    setState(() {
      isRunning = true;
    });

    // Reset grid before starting
    resetGrid(keepObstacles: true);

    Queue<Node> queue = Queue<Node>();
    queue.add(startNode);
    startNode.isVisited = true;

    while (queue.isNotEmpty) {
      Node current = queue.removeFirst();

      setState(() {
        current.isVisited = true;
      });
      await Future.delayed(visitedAnimDuration);

      // If we found the end node
      if (current == endNode) {
        await animatePath();
        setState(() {
          isRunning = false;
        });
        return;
      }

      // Check all neighbors
      for (Node neighbor in getNeighbors(current)) {
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

  // Choose algorithm to run
  Future<void> runAlgorithm() async {
    switch (selectedAlgorithm) {
      case 'Dijkstra':
        await runDijkstra();
        break;
      case 'DFS':
        await runDFS();
        break;
      case 'BFS':
        await runBFS();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Maze Solver',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _animation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Algorithm selector
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: gridBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Algorithm:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButton<String>(
                      value: selectedAlgorithm,
                      dropdownColor: gridBackgroundColor,
                      underline: Container(),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white),
                      style: const TextStyle(color: Colors.white),
                      onChanged: isRunning
                          ? null
                          : (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedAlgorithm = newValue;
                                });
                              }
                            },
                      items: algorithms
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Legend
              Container(
                padding: const EdgeInsets.all(8.0),
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

              // Grid display
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: gridBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(4.0),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: numCols,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: numRows * numCols,
                      itemBuilder: (context, index) {
                        int row = index ~/ numCols;
                        int col = index % numCols;
                        Node node = grid[row][col];

                        // Determine cell color based on its state.
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
                            // Allow toggling obstacles only if not running and not a start/end node.
                            if (!isRunning &&
                                node != startNode &&
                                node != endNode) {
                              setState(() {
                                node.isObstacle = !node.isObstacle;
                              });
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: node.isObstacle
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: node == startNode
                                ? const Icon(Icons.play_arrow,
                                    color: Colors.white, size: 14)
                                : node == endNode
                                    ? const Icon(Icons.flag,
                                        color: Colors.white, size: 14)
                                    : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildButton(
                    'Start',
                    Icons.play_arrow,
                    isRunning ? null : runAlgorithm,
                  ),
                  _buildButton(
                    'Reset Path',
                    Icons.refresh,
                    isRunning ? null : () => resetGrid(keepObstacles: true),
                  ),
                  _buildButton(
                    'Clear All',
                    Icons.delete_outline,
                    isRunning ? null : () => resetGrid(keepObstacles: false),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback? onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        shadowColor: buttonColor.withOpacity(0.5),
        disabledBackgroundColor: buttonColor.withOpacity(0.3),
        disabledForegroundColor: Colors.white.withOpacity(0.5),
      ),
    );
  }
}

// Optimized priority queue implementation
class HeapPriorityQueue<E> {
  final Comparator<E> _comparison;
  final List<E> _queue = <E>[];

  HeapPriorityQueue(int Function(E, E) comparison) : _comparison = comparison;

  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;
  int get length => _queue.length;

  void add(E element) {
    _queue.add(element);
    _siftUp(_queue.length - 1);
  }

  E removeFirst() {
    final E result = _queue.first;
    final E last = _queue.removeLast();
    if (_queue.isNotEmpty) {
      _queue[0] = last;
      _siftDown(0);
    }
    return result;
  }

  void _siftUp(int index) {
    final E element = _queue[index];
    while (index > 0) {
      int parentIndex = (index - 1) ~/ 2;
      E parent = _queue[parentIndex];
      if (_comparison(element, parent) >= 0) break;
      _queue[index] = parent;
      index = parentIndex;
    }
    _queue[index] = element;
  }

  void _siftDown(int index) {
    final int end = _queue.length;
    final E element = _queue[index];
    while (true) {
      int childIndex = index * 2 + 1;
      if (childIndex >= end) break;
      E child = _queue[childIndex];
      int rightChildIndex = childIndex + 1;
      if (rightChildIndex < end) {
        E rightChild = _queue[rightChildIndex];
        if (_comparison(rightChild, child) < 0) {
          childIndex = rightChildIndex;
          child = rightChild;
        }
      }
      if (_comparison(element, child) <= 0) break;
      _queue[index] = child;
      index = childIndex;
    }
    _queue[index] = element;
  }
}
