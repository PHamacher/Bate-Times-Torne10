import streamlit as st
from ortools.linear_solver import pywraplp

todos = [["Murilo", "Almeida", "Felipe", "Coelho", "Vinisk", "Hama", "Bob", "Tuca", "Cingo", "Elabras", "Lucca", "Miguel", "Sommer", "Mello", "TT", "Joebo"]]
Klis = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]]
P = [0,1,2,3]
n_pos = [0]


def bate_times(ovrs, players, juntos, separados):
    media = sum(ovrs[0]) / len(ovrs[0])
    # Create the solver
    solver = pywraplp.Solver.CreateSolver('SCIP')

    # Variables
    x = {}
    for i in range(len(todos)):
        for k in Klis[i]:
            for p in P:
                x[i, k, p] = solver.IntVar(0, 1, '')

    s = [solver.NumVar(0, solver.infinity(), '') for _ in P]
    z = [solver.NumVar(0, solver.infinity(), '') for _ in P]
    alpha = solver.NumVar(0, solver.infinity(), '')

    # Constraints
    for n in range(len(todos)):
        for j in P:
            solver.Add(sum(x[n, i, j] for i in Klis[n]) == len(Klis[n]) / len(P))
        for i in Klis[n]:
            solver.Add(sum(x[n, i, j] for j in P) == 1)

    for j in P:
        solver.Add(s[j] == sum(sum(ovrs[k][i] * x[k, i, j] for i in Klis[k]) for k in n_pos))
        solver.Add(media - s[j] <= z[j])
        solver.Add(s[j] - media <= z[j])
        solver.Add(z[j] <= alpha)

    for group in juntos:
        for team in P:
            for i in range(len(group) - 1):
                for j in range(i + 1, len(group)):
                    solver.Add(x[0, group[i], team] == x[0, group[j], team])

    # Add constraints for groups that should be separated
    for group in separados:
        for team in P:
            solver.Add(sum(x[0, player, team] for player in group) <= 1)

    # Objective
    objective = solver.Objective()
    objective.SetCoefficient(alpha, 1)
    objective.SetMinimization()

    # Solve the problem
    status = solver.Solve()

    teams = list(P)
    team_assignments = get_teams(x, players, teams)
    return team_assignments

def get_teams(x, player_names, teams):
    team_assignments = {team: [] for team in teams}
    for key, value in x.items():
        if value.solution_value() == 1:
            _, player, team = key
            team_assignments[team].append(player_names[player])
    return team_assignments

# Streamlit app
st.title('Batedor de Times oficial do Torne10')
st.markdown("## Escolha abaixo o nível de cada jogador na sua opinião")

# Input for player overalls
ovrs = []
for i in range(16):
    # ovrs.append(st.slider(todos[0][i], min_value=0, max_value=100, value=50))
    ovrs.append(st.number_input(todos[0][i], value=50, placeholder="Digite o overall do jogador", step=1))

# Input for groups of players
st.markdown("## Separar e juntar jogadores")
st.markdown("Se você quiser, pode forçar jogadores a ficarem juntos no mesmo time ou a serem separados")
player_names = [todos[0][i] for i in range(16)]
groups_together = []
groups_separated = []
st.markdown("### Juntar jogadores em um mesmo time")
st.markdown("Se você quer que dois ou mais jogadores joguem no mesmo time, selecione-os abaixo")
group_count = st.number_input("Quantos grupos de jogadores juntos você quer criar?", min_value=0, value=0)
for i in range(group_count):
    group = st.multiselect(f"Grupo {i+1}", options=player_names, key = f"Juntos {i}")
    groups_together.append([player_names.index(player) for player in group])

st.markdown("### Separar jogadores em times diferentes")
st.markdown("Se você quer que dois ou mais jogadores joguem em times diferentes, selecione-os abaixo")
group_count = st.number_input("Quantos grupos de jogadores separados você quer criar?", min_value=0, value=0)
for i in range(group_count):
    group = st.multiselect(f"Grupo {i+1}", options=player_names, key = f"Separados {i}")
    groups_separated.append([player_names.index(player) for player in group])


# Button to solve the problem
if st.button('Bate Times'):
    solution = bate_times([ovrs], todos[0], groups_together, groups_separated)
    
    # Format the solution as a Markdown string
    st.markdown("## Times")

    solution_md = ""
    for team, players in solution.items():
        solution_md += f"**Time {team+1}**\n"
        for player in players:
            solution_md += f"- {player}\n"
        solution_md += "\n"
    
    # Display the solution
    st.markdown(solution_md)


