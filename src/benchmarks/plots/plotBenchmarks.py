import argparse
import pandas as pd
import matplotlib.pyplot as plt

def plot_from_csv(csv_file, x_var, y_var, group_var):
    # Read the CSV file
    df = pd.read_csv(csv_file, delimiter=';')

    # Convert the group variable to a string for categorical grouping
    df[group_var] = df[group_var].astype(str)

    # Create the plot
    plt.figure(figsize=(10, 6))

    for group in df[group_var].unique():
        subset = df[df[group_var] == group]
        plt.plot(subset[x_var], subset[y_var], marker='o', label=f"{group} {group_var}")

    plt.xscale('log') if df[x_var].max() / df[x_var].min() > 100 else None  # Use log scale if range is large
    plt.yscale('log') if df[y_var].max() / df[y_var].min() > 100 else None  # Use log scale if range is large

    plt.xlabel(x_var)
    plt.ylabel(y_var)
    plt.title(f"{y_var} vs {x_var} grouped by {group_var}")
    plt.legend()
    plt.grid(True, which="both", linestyle="--", linewidth=0.5)
    plt.show()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Plot benchmark data with flexible axes and grouping.")
    parser.add_argument("csv_file", type=str, help="Path to the CSV file containing the benchmark data.")
    parser.add_argument("x_var", type=str, help="Column name for x-axis variable.")
    parser.add_argument("y_var", type=str, help="Column name for y-axis variable.")
    parser.add_argument("group_var", type=str, help="Column name for grouping variable (separate lines).")

    args = parser.parse_args()
    
    plot_from_csv(args.csv_file, args.x_var, args.y_var, args.group_var)


