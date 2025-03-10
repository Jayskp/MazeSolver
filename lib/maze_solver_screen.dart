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

class _MazeSolverScreenState extends State<MazeSolverScreen> {
  static const int numRows = 20;
  static const int numCols = 20;
  late List<List<Node>> grid;
  late Node startNode;
  late Node endNode;
  bool isRunning = false;

  // Define algorithm options
  final List<String> algorithms = ['Dijkstra', 'A*', 'BFS'];
  String selectedAlgorithm = 'Dijkstra';

  @override
  void initState() {
    super.initState();
    initGrid();
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

  // Calculate Manhattan distance for heuristic
  double getManhattanDistance(Node a, Node b) {
    return (a.row - b.row).abs() + (a.col - b.col).abs().toDouble();
  }

  // Returns valid neighbors (up, down, left, right) for a given node.
  List<Node> getNeighbors(Node node) {
    List<Node> neighbors = [];
    int r = node.row;
    int c = node.col;

    // Check all 4 directions
    final directions = [
      if (r > 0) grid[r - 1][c],                // Up
      if (r < numRows - 1) grid[r + 1][c],      // Down
      if (c > 0) grid[r][c - 1],                // Left
      if (c < numCols - 1) grid[r][c + 1],      // Right
    ];

    return directions;
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
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }

  // Runs Dijkstra's algorithm with animation.
  Future<void> runDijkstra() async {
    setState(() {
      isRunning = true;
    });

    // Use a priority queue for better performance
    final unvisitedQueue = PriorityQueue<Node>((a, b) =>
        a.distance.compareTo(b.distance));

    // Reset grid before starting
    resetGrid(keepObstacles: true);
    startNode.distance = 0;

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
      await Future.delayed(const Duration(milliseconds: 20));

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

  // A* search algorithm
  Future<void> runAStar() async {
    setState(() {
      isRunning = true;
    });

    // Reset grid before starting
    resetGrid(keepObstacles: true);
    startNode.distance = 0;

    // Create open and closed sets
    final openSet = <Node>{startNode};
    final closedSet = <Node>{};

    // Create map for f-scores (distance + heuristic)
    final Map<Node, double> fScore = {};
    for (var row in grid) {
      for (var node in row) {
        fScore[node] = double.infinity;
      }
    }
    fScore[startNode] = getManhattanDistance(startNode, endNode);

    while (openSet.isNotEmpty) {
      // Get node with lowest f-score
      Node current = openSet.reduce((a, b) =>
      fScore[a]! < fScore[b]! ? a : b);

      // If current is the end, we're done
      if (current == endNode) {
        await animatePath();
        setState(() {
          isRunning = false;
        });
        return;
      }

      // Move current from open to closed set
      openSet.remove(current);
      closedSet.add(current);

      setState(() {
        current.isVisited = true;
      });
      await Future.delayed(const Duration(milliseconds: 20));

      // Check all neighbors
      for (Node neighbor in getNeighbors(current)) {
        if (closedSet.contains(neighbor) || neighbor.isObstacle) continue;

        // Calculate tentative g-score
        double tentativeGScore = current.distance + 1;

        // If neighbor not in open set, add it
        if (!openSet.contains(neighbor)) {
          openSet.add(neighbor);
        }
        // If this path is worse, skip it
        else if (tentativeGScore >= neighbor.distance) {
          continue;
        }

        // This is the best path so far
        setState(() {
          neighbor.previous = current;
          neighbor.distance = tentativeGScore;
          fScore[neighbor] = tentativeGScore + getManhattanDistance(neighbor, endNode);
        });
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
      await Future.delayed(const Duration(milliseconds: 20));

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
      case 'A*':
        await runAStar();
        break;
      case 'BFS':
        await runBFS();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maze Solver'),
      ),
      body: Column(
        children: [
          // Algorithm selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Algorithm: '),
                DropdownButton<String>(
                  value: selectedAlgorithm,
                  onChanged: isRunning
                      ? null
                      : (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedAlgorithm = newValue;
                      });
                    }
                  },
                  items: algorithms.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Grid display
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: numCols,
                childAspectRatio: 1.0,
              ),
              itemCount: numRows * numCols,
              itemBuilder: (context, index) {
                int row = index ~/ numCols;
                int col = index % numCols;
                Node node = grid[row][col];

                // Determine cell color based on its state.
                Color color;
                if (node == startNode) {
                  color = Colors.green;
                } else if (node == endNode) {
                  color = Colors.red;
                } else if (node.isPath) {
                  color = Colors.yellow;
                } else if (node.isObstacle) {
                  color = Colors.black;
                } else if (node.isVisited) {
                  color = Colors.lightBlueAccent;
                } else {
                  color = Colors.white;
                }

                return GestureDetector(
                  onTap: () {
                    // Allow toggling obstacles only if not running and not a start/end node.
                    if (!isRunning && node != startNode && node != endNode) {
                      setState(() {
                        node.isObstacle = !node.isObstacle;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: Colors.grey.shade300, width: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),

          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: isRunning ? null : runAlgorithm,
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: isRunning
                      ? null
                      : () => resetGrid(keepObstacles: true),
                  child: const Text('Reset Path'),
                ),
                ElevatedButton(
                  onPressed: isRunning
                      ? null
                      : () => resetGrid(keepObstacles: false),
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}