import heapq
import random
import math
from collections import deque
from typing import List, Tuple, Dict, Any, Set, Optional

# 8-Puzzle Implementation
class EightPuzzle:
    def __init__(self, initial_state=None):
        if initial_state is None:
            # Create a random initial state
            numbers = list(range(9))  # 0-8, where 0 represents the empty space
            random.shuffle(numbers)
            self.initial_state = [numbers[i:i+3] for i in range(0, 9, 3)]
        else:
            self.initial_state = initial_state
            
        self.goal_state = [[1, 2, 3], [4, 5, 6], [7, 8, 0]]
        
    def get_blank_position(self, state):
        """Find the position of the blank (0) in the puzzle."""
        for i in range(3):
            for j in range(3):
                if state[i][j] == 0:
                    return (i, j)
        return None
    
    def get_neighbors(self, state):
        """Get all possible next states by moving the blank."""
        i, j = self.get_blank_position(state)
        neighbors = []
        
        # Possible moves: up, down, left, right
        moves = [(i-1, j), (i+1, j), (i, j-1), (i, j+1)]
        
        for move_i, move_j in moves:
            if 0 <= move_i < 3 and 0 <= move_j < 3:
                new_state = [row[:] for row in state]  # Deep copy
                new_state[i][j], new_state[move_i][move_j] = new_state[move_i][move_j], new_state[i][j]
                neighbors.append(new_state)
                
        return neighbors
    
    def is_goal(self, state):
        """Check if the current state is the goal state."""
        return state == self.goal_state
    
    def state_to_string(self, state):
        """Convert a state to a string for hashing."""
        return ''.join(''.join(str(cell) for cell in row) for row in state)
    
    def manhattan_distance(self, state):
        """Calculate the Manhattan distance heuristic."""
        distance = 0
        for i in range(3):
            for j in range(3):
                if state[i][j] != 0:  # Skip the blank
                    # Find where this number should be in the goal state
                    goal_i, goal_j = (state[i][j] - 1) // 3, (state[i][j] - 1) % 3
                    distance += abs(i - goal_i) + abs(j - goal_j)
        return distance
    
    # Breadth-First Search
    def solve_bfs(self):
        """Solve the puzzle using Breadth-First Search."""
        queue = deque([(self.initial_state, [])])  # (state, path)
        visited = set([self.state_to_string(self.initial_state)])
        
        while queue:
            state, path = queue.popleft()
            
            if self.is_goal(state):
                return path
            
            for neighbor in self.get_neighbors(state):
                neighbor_str = self.state_to_string(neighbor)
                if neighbor_str not in visited:
                    visited.add(neighbor_str)
                    queue.append((neighbor, path + [neighbor]))
        
        return None  # No solution found
    
    # Bidirectional Search
    def solve_bidirectional(self):
        """Solve the puzzle using Bidirectional Search."""
        # Forward search from initial state
        forward_queue = deque([(self.initial_state, [])])  # (state, path)
        forward_visited = {self.state_to_string(self.initial_state): []}
        
        # Backward search from goal state
        backward_queue = deque([(self.goal_state, [])])  # (state, path)
        backward_visited = {self.state_to_string(self.goal_state): []}
        
        while forward_queue and backward_queue:
            # Forward search step
            state, path = forward_queue.popleft()
            state_str = self.state_to_string(state)
            
            # Check if this state has been visited by backward search
            if state_str in backward_visited:
                # Found a meeting point
                backward_path = backward_visited[state_str]
                # Reverse the backward path and combine with forward path
                return path + list(reversed(backward_path))
            
            for neighbor in self.get_neighbors(state):
                neighbor_str = self.state_to_string(neighbor)
                if neighbor_str not in forward_visited:
                    forward_visited[neighbor_str] = path + [neighbor]
                    forward_queue.append((neighbor, path + [neighbor]))
            
            # Backward search step
            state, path = backward_queue.popleft()
            state_str = self.state_to_string(state)
            
            # Check if this state has been visited by forward search
            if state_str in forward_visited:
                # Found a meeting point
                forward_path = forward_visited[state_str]
                # Combine forward path with reversed backward path
                return forward_path + list(reversed(path))
            
            for neighbor in self.get_neighbors(state):
                neighbor_str = self.state_to_string(neighbor)
                if neighbor_str not in backward_visited:
                    backward_visited[neighbor_str] = path + [neighbor]
                    backward_queue.append((neighbor, path + [neighbor]))
        
        return None  # No solution found
    
    # Simulated Annealing
    def solve_simulated_annealing(self, max_iterations=10000, initial_temp=1.0, cooling_rate=0.995):
        """Solve the puzzle using Simulated Annealing."""
        current_state = self.initial_state
        current_energy = self.manhattan_distance(current_state)
        best_state = current_state
        best_energy = current_energy
        temperature = initial_temp
        
        path = [current_state]
        
        for iteration in range(max_iterations):
            if current_energy == 0:  # Found the goal
                return path
            
            # Get a random neighbor
            neighbors = self.get_neighbors(current_state)
            next_state = random.choice(neighbors)
            next_energy = self.manhattan_distance(next_state)
            
            # Decide whether to accept the new state
            if next_energy < current_energy:
                # Accept better state
                current_state = next_state
                current_energy = next_energy
                path.append(current_state)
                
                if current_energy < best_energy:
                    best_state = current_state
                    best_energy = current_energy
            else:
                # Accept worse state with a probability based on temperature
                delta_energy = next_energy - current_energy
                acceptance_probability = math.exp(-delta_energy / temperature)
                
                if random.random() < acceptance_probability:
                    current_state = next_state
                    current_energy = next_energy
                    path.append(current_state)
            
            # Cool down
            temperature *= cooling_rate
            
            # If temperature is very low, restart from the best state
            if temperature < 0.01:
                current_state = best_state
                current_energy = best_energy
                temperature = initial_temp * 0.5
        
        return path  # Return the best path found

# Example usage
if __name__ == "__main__":
    # Create a puzzle with a random initial state
    puzzle = EightPuzzle()
    
    print("Initial state:")
    for row in puzzle.initial_state:
        print(row)
    
    print("\nGoal state:")
    for row in puzzle.goal_state:
        print(row)
    
    print("\nSolving with BFS...")
    bfs_solution = puzzle.solve_bfs()
    if bfs_solution:
        print(f"BFS found a solution in {len(bfs_solution)} moves")
    else:
        print("BFS could not find a solution")
    
    print("\nSolving with Bidirectional Search...")
    bidirectional_solution = puzzle.solve_bidirectional()
    if bidirectional_solution:
        print(f"Bidirectional Search found a solution in {len(bidirectional_solution)} moves")
    else:
        print("Bidirectional Search could not find a solution")
    
    print("\nSolving with Simulated Annealing...")
    annealing_solution = puzzle.solve_simulated_annealing()
    if annealing_solution:
        print(f"Simulated Annealing found a solution in {len(annealing_solution)} moves")
    else:
        print("Simulated Annealing could not find a solution")
