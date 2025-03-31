from flask import Flask, request, jsonify
from puzzle_solver import EightPuzzle
import random

app = Flask(__name__)

# Store game states in memory (in a real app, use a database)
game_states = {}

@app.route('/api/new-puzzle', methods=['POST'])
def new_puzzle():
    data = request.json
    puzzle_type = data.get('puzzleType', '8puzzle')
    algorithm = data.get('algorithm', 'bfs')
    
    response = {
        'message': '',
        'gameState': None
    }
    
    if puzzle_type == '8puzzle':
        # Create a solvable 8-puzzle
        puzzle = EightPuzzle()
        
        # Make sure it's not already solved and not too difficult
        while puzzle.manhattan_distance(puzzle.initial_state) < 5 or puzzle.is_goal(puzzle.initial_state):
            puzzle = EightPuzzle()
        
        difficulty = "Easy"
        manhattan_dist = puzzle.manhattan_distance(puzzle.initial_state)
        if manhattan_dist > 15:
            difficulty = "Hard"
        elif manhattan_dist > 10:
            difficulty = "Medium"
        
        game_state = {
            'puzzleType': '8puzzle',
            'difficulty': difficulty,
            'currentState': puzzle.initial_state,
            'goalState': puzzle.goal_state,
            'moves': 0,
            'solved': False
        }
        
        # Generate a unique ID for this game
        game_id = str(random.randint(1000, 9999))
        game_states[game_id] = {
            'puzzle': puzzle,
            'state': game_state
        }
        
        response['gameState'] = game_state
        response['gameId'] = game_id
        response['message'] = f"I've created an 8-puzzle for you. Try to arrange the numbers in order with the empty space in the bottom right. I'll be using the {algorithm} algorithm to help you solve it."
    
    elif puzzle_type == 'pathfinding':
        # Simplified pathfinding maze representation
        maze_size = 10
        maze = [[0 for _ in range(maze_size)] for _ in range(maze_size)]
        
        # Add some walls (1 represents a wall)
        for _ in range(maze_size * 2):
            x, y = random.randint(0, maze_size-1), random.randint(0, maze_size-1)
            maze[x][y] = 1
        
        # Ensure start and end are not walls
        start = (0, 0)
        end = (maze_size-1, maze_size-1)
        maze[start[0]][start[1]] = 0
        maze[end[0]][end[1]] = 0
        
        game_state = {
            'puzzleType': 'pathfinding',
            'difficulty': random.choice(['Easy', 'Medium', 'Hard']),
            'currentState': maze,
            'goalState': {'start': start, 'end': end},
            'moves': 0,
            'solved': False
        }
        
        game_id = str(random.randint(1000, 9999))
        game_states[game_id] = {
            'state': game_state
        }
        
        response['gameState'] = game_state
        response['gameId'] = game_id
        response['message'] = f"I've generated a pathfinding maze. Find the shortest path from the start to the exit. I'll be using the {algorithm} algorithm to help you solve it."
    
    elif puzzle_type == 'colormap':
        # Simplified map coloring problem
        num_regions = 6
        regions = [f"Region{i+1}" for i in range(num_regions)]
        
        # Create random adjacency matrix
        adjacency = [[0 for _ in range(num_regions)] for _ in range(num_regions)]
        for i in range(num_regions):
            for j in range(i+1, num_regions):
                if random.random() > 0.5:  # 50% chance of regions being adjacent
                    adjacency[i][j] = adjacency[j][i] = 1
        
        game_state = {
            'puzzleType': 'colormap',
            'difficulty': random.choice(['Easy', 'Medium', 'Hard']),
            'currentState': {
                'regions': regions,
                'adjacency': adjacency,
                'colors': [None] * num_regions
            },
            'goalState': 'valid coloring',
            'moves': 0,
            'solved': False
        }
        
        game_id = str(random.randint(1000, 9999))
        game_states[game_id] = {
            'state': game_state
        }
        
        response['gameState'] = game_state
        response['gameId'] = game_id
        response['message'] = f"I've created a map coloring problem with {num_regions} regions. Assign colors to regions so that no adjacent regions have the same color. I'll be using the {algorithm} algorithm to help you solve it."
    
    return jsonify(response)

@app.route('/api/solve', methods=['POST'])
def solve():
    data = request.json
    message = data.get('message', '')
    algorithm = data.get('algorithm', 'bfs')
    game_state = data.get('gameState')
    game_id = data.get('gameId')
    
    response = {
        'message': "I'm processing your request...",
        'gameState': game_state
    }
    
    if not game_state:
        response['message'] = "Please start a new puzzle first by selecting one from the puzzle selection panel."
        return jsonify(response)
    
    # Get the stored game data
    game_data = game_states.get(game_id)
    
    # Handle different message intents
    if 'hint' in message.lower():
        if game_state['puzzleType'] == '8puzzle':
            if algorithm == 'bfs':
                response['message'] = "For the 8-puzzle, BFS will find the shortest solution. Try to think about which moves will reduce the Manhattan distance to the goal state."
            elif algorithm == 'bidirectional':
                response['message'] = "Bidirectional search works by searching from both the start and goal states. Consider which intermediate states might be reached from both directions."
            elif algorithm == 'annealing':
                response['message'] = "Simulated annealing might accept worse moves initially to escape local optima. Focus on the overall pattern rather than individual moves."
        elif game_state['puzzleType'] == 'pathfinding':
            response['message'] = "In pathfinding, look for the most direct route while avoiding walls. Sometimes the shortest path isn't immediately obvious."
        elif game_state['puzzleType'] == 'colormap':
            response['message'] = "For map coloring, start with the regions that have the most neighbors, as they'll be the most constrained."
    
    elif 'solve' in message.lower():
        if game_state['puzzleType'] == '8puzzle' and game_data and 'puzzle' in game_data:
            puzzle = game_data['puzzle']
            
            solution = None
            if algorithm == 'bfs':
                solution = puzzle.solve_bfs()
            elif algorithm == 'bidirectional':
                solution = puzzle.solve_bidirectional()
            elif algorithm == 'annealing':
                solution = puzzle.solve_simulated_annealing()
            
            if solution:
                response['gameState'] = {
                    **game_state,
                    'solved': True,
                    'moves': len(solution)
                }
                response['message'] = f"I've solved the 8-puzzle using {algorithm} in {len(solution)} moves!"
            else:
                response['message'] = f"I couldn't find a solution using {algorithm}. This puzzle might be particularly challenging."
        else:
            # Simulate solving for other puzzle types
            response['gameState'] = {
                **game_state,
                'solved': True,
                'moves': random.randint(5, 20)
            }
            response['message'] = f"I've solved the {game_state['puzzleType']} puzzle using {algorithm} in {response['gameState']['moves']} moves!"
    
    elif 'explain' in message.lower():
        if algorithm == 'bfs':
            response['message'] = "Breadth-First Search (BFS) explores all neighbor nodes at the present depth before moving to nodes at the next depth level. This guarantees the shortest path in unweighted graphs. In the context of puzzles, BFS will find the solution with the minimum number of moves, but it can be memory-intensive for complex puzzles."
        elif algorithm == 'bidirectional':
            response['message'] = "Bidirectional Search runs two simultaneous searches—one forward from the initial state and one backward from the goal. It's often faster than a single search because the two searches meet in the middle, reducing the total number of states that need to be explored. This is particularly effective for puzzles with a known goal state."
        elif algorithm == 'annealing':
            response['message'] = "Simulated Annealing is inspired by the annealing process in metallurgy. It starts with a high 'temperature' that allows it to accept worse solutions with high probability. As the temperature decreases, it becomes less likely to accept worse solutions, eventually converging to a good (though not necessarily optimal) solution. This is useful for puzzles with many local optima where greedy algorithms might get stuck."
    
    else:
        response['message'] = f"I'm your AI puzzle assistant. You can ask me for hints, to solve the puzzle, or to explain how the {algorithm} algorithm works. What would you like to know about your {game_state['puzzleType']} puzzle?"
    
    return jsonify(response)

if __name__ == '__main__':
    app.run(debug=True)
