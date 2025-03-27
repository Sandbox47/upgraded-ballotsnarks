import argparse
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import json
from scipy.interpolate import interp1d

def load_config(config_path):
    with open(config_path, "r") as f:
        return json.load(f)

def load_and_filter_data(file_name, filter_variable, filter_value, x_name, y_name, scaling_factor=1.0):
    df = pd.read_csv(file_name, delimiter=";")
    df.columns = df.columns.str.strip()  # Strip spaces from column names
    # print("CSV Columns:", df.columns)  # Debugging print

    if filter_variable:
        df = df[df[filter_variable] == filter_value]
    x = df[x_name].values
    y = df[y_name].values * scaling_factor
    return x, y

def plot_data(entry):
    plt.figure(figsize=(8, 6))
    plt.xlabel(entry["xLabel"])
    plt.ylabel(entry["yLabel"])
    plt.xlim(0, entry["xLimit"])
    plt.ylim(0, entry["yLimit"])
    plt.title(entry["label"])
    
    for dataset in entry["dataSets"]:
        file_name = dataset["fileName"]
        filter_variable = dataset.get("filterVariable")
        x_name = dataset["xNameData"]
        y_name = dataset["yNameData"]
        scaling_factor = dataset.get("scalingFactor", 1.0)
        
        for line in dataset["lines"]:
            filter_value = line.get("filterValue")
            color = line["color"]
            linestyle = line["linestyle"]
            label = line["label"]
            
            x, y = load_and_filter_data(file_name, filter_variable, filter_value, x_name, y_name, scaling_factor)
            # plt.plot(x, y, color=color, linestyle=linestyle, label=label)

            # Interpolation
            if len(x) > 1:
                interp_func = interp1d(x, y, kind='cubic', fill_value='extrapolate')
                x_smooth = np.linspace(min(x), max(x), 300)  # Generate smooth x values
                y_smooth = interp_func(x_smooth)
                plt.plot(x_smooth, y_smooth, color=color, linestyle=linestyle, label=label)
            else:
                plt.plot(x, y, color=color, linestyle=linestyle, label=label)  # Fallback if not enough points
    
    plt.legend(loc='center left', bbox_to_anchor=(1, 0.5))  # Move legend to the right
    plt.grid()

    output_path = os.path.join("plots", f"{entry['plotPath']}.pdf")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)  # Ensure the directory exists
    plt.savefig(output_path, format="pdf", bbox_inches='tight')  # Adjust bounding box for legend
    plt.close()

def main():
    config = load_config("plotSuite.json")
    for entry in config:
        plot_data(entry)

if __name__ == "__main__":
    main()







































"""
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
"""