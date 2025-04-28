import sys
import os
import pandas as pd
import numpy as np
from matplotlib import pyplot as plt
import matplotlib as mpl
import json
from scipy.interpolate import interp1d
from sklearn.linear_model import LinearRegression
from numpy.polynomial.polynomial import Polynomial
from math import ceil

# mpl.rcParams['text.usetex'] = True
# mpl.rcParams['text.latex.preamble'] = [r'\usepackage{amsmath}'] #for \text command

def load_config(config_path):
    with open(config_path, "r") as f:
        return json.load(f)

def load_and_filter_data(file_name, filter_variable, filter_value, x_name, y_name, scaling_factor=1.0):
    df = pd.read_csv(file_name, delimiter=";")
    df.columns = df.columns.str.strip()  # Strip spaces from column names
    # print("CSV Columns:", df.columns)  # Debugging print

    if filter_variable:
        if '=' in filter_variable and filter_variable.count('=') == 1: #and filter_variable.replace('=', '').isidentifier():
            col1, col2 = filter_variable.split('=')
            df = df[df[col1] == df[col2]]
        else:
            df = df[df[filter_variable] == filter_value]

    x = df[x_name].values
    y = df[y_name].values * scaling_factor
    # print(f"Y-Values: {y}")
    return x, y

def plot_data_given_yLabel(entry, yLabel, ax):
    config = load_config("plotConfig.json")
    ax.set_xlabel(entry["xLabel"])
    ax.set_ylabel(yLabel)
    ax.set_xlim(0, entry["xLimit"])

    labels = config["labels"]
    ax.set_title(labels[yLabel] + entry["label"])

    for dataset in entry["dataSets"]:
        mode = dataset["mode"]
        if not(yLabel in config[mode]):
            continue
        modeConfig = config[mode][yLabel]

        file_name = dataset["fileName"]
        filter_variable = dataset.get("filterVariable")
        x_name = dataset["xNameData"]
        y_name = modeConfig["name"]
        scaling_factor = modeConfig.get("scalingFactor", 1.0)
        linestyle = dataset["linestyle"]
        interpolation_degree = dataset.get("interpolationDegree", 1)

        for line in dataset["lines"]:
            filter_value = line.get("filterValue")
            color = line["color"]
            label = line["label"]

            x, y = load_and_filter_data(file_name, filter_variable, filter_value, x_name, y_name, scaling_factor)
            ax.scatter(x, y, color=color, s=10)

            if len(x) > interpolation_degree:
                coeffs = np.polyfit(x, y, interpolation_degree)
                poly = np.poly1d(coeffs)
                x_dense = np.linspace(np.min(x), np.max(x), 300)
                ax.plot(x_dense, poly(x_dense), color=color, linestyle=linestyle, label=label)

                # if interpolation_degree == 1:
                #     slope = coeffs[0]
                #     label_with_slope = f"{label} (slope: {slope:.2e})"
                #     ax.plot(x_dense, poly(x_dense), color=color, linestyle=linestyle, label=label_with_slope)
                # elif interpolation_degree >= 2:
                #     curvature = coeffs[0]  # leading coefficient for x^2
                #     label_with_curvature = f"{label} (leading coef: {curvature:.2e})"
                #     ax.plot(x_dense, poly(x_dense), color=color, linestyle=linestyle, label=label_with_curvature)
                # else:
                #     ax.plot(x_dense, poly(x_dense), color=color, linestyle=linestyle, label=label)

            else:
                ax.plot(x, y, color=color, linestyle=linestyle, label=label)

    ax.grid()


""""
def plot_data_given_yLabel(entry, yLabel, output_path):
    config = load_config("plotConfig.json")

    plt.figure(figsize=(8, 6))
    plt.xlabel(entry["xLabel"])
    plt.ylabel(yLabel)
    plt.xlim(0, entry["xLimit"])
    # plt.ylim(0, entry["yLimit"])
    labels = config["labels"]
    plt.title(labels[yLabel] + entry["label"])
    
    for dataset in entry["dataSets"]:
        mode = dataset["mode"]
        if not(yLabel in config[mode]):
            continue
        modeConfig = config[mode][yLabel]

        file_name = dataset["fileName"]
        filter_variable = dataset.get("filterVariable")
        x_name = dataset["xNameData"]
        y_name = modeConfig["name"]
        scaling_factor = modeConfig.get("scalingFactor", 1.0)
        linestyle = dataset["linestyle"]
        interpolation_degree = dataset.get("interpolationDegree", 1)
        
        for line in dataset["lines"]:
            filter_value = line.get("filterValue")
            color = line["color"]
            label = line["label"]
            
            x, y = load_and_filter_data(file_name, filter_variable, filter_value, x_name, y_name, scaling_factor)
            # plt.plot(x, y, color=color, linestyle=linestyle, label=label)

            # Interpolation
            # if len(x) > 1:
            #     interp_func = interp1d(x, y, kind='cubic', fill_value='extrapolate')
            #     x_smooth = np.linspace(min(x), max(x), 300)  # Generate smooth x values
            #     y_smooth = interp_func(x_smooth)
            #     plt.plot(x_smooth, y_smooth, color=color, linestyle=linestyle, label=label)
            # else:
            #     plt.plot(x, y, color=color, linestyle=linestyle, label=label)  # Fallback if not enough points

            # Plot data points
            plt.scatter(x, y, color=color, s=10)

            if len(x) > interpolation_degree:
                # print(f"election type: {label}, interpolation degree: {interpolation_degree}")
                # Polynomial regression of specified degree
                coeffs = np.polyfit(x, y, interpolation_degree)
                poly = np.poly1d(coeffs)
                # x_sorted = np.sort(x)
                # plt.plot(x_sorted, poly(x_sorted), color=color, linestyle=linestyle, label=label)
                x_dense = np.linspace(np.min(x), np.max(x), 300)  # Generate smooth range
                plt.plot(x_dense, poly(x_dense), color=color, linestyle=linestyle, label=label)
            else:
                print(f"Interpolation not possible, {len(x)} <= {interpolation_degree}")
                plt.plot(x, y, color=color, linestyle=linestyle, label=label)  # Fallback
    
    plt.legend(loc='center left', bbox_to_anchor=(1, 0.5))  # Move legend to the right
    plt.grid()

    os.makedirs(os.path.dirname(output_path), exist_ok=True)  # Ensure the directory exists
    plt.savefig(output_path, format="pdf", bbox_inches='tight')  # Adjust bounding box for legend
    plt.close()
"""

def plot_data(entry):
    # config = load_config("plotConfig.json")
    # yLabels = config["yLabels"]
    # for yLabel in yLabels:
    #     output_path = entry['plotPath'] + yLabel
    #     output_path = os.path.join("plots", f"{output_path}.pdf")
    #     plot_data_given_yLabel(entry, yLabel, output_path)

    config = load_config("plotConfig.json")
    yLabels = config["yLabels"]
    n_plots = len(yLabels)
    ncols = 2 if n_plots > 1 else 1
    nrows = ceil(n_plots / ncols)

    fig, axs = plt.subplots(nrows, ncols, figsize=(ncols * 6, nrows * 5.5))
    axs = axs.flatten() if n_plots > 1 else [axs]

    handles_labels = []
    for i, yLabel in enumerate(yLabels):
        plot_data_given_yLabel(entry, yLabel, axs[i])
        handles_labels.append(axs[i].get_legend_handles_labels())

    # Hide any unused subplot
    for j in range(n_plots, len(axs)):
        axs[j].axis('off')

    # Collect all legend entries and remove duplicates
    handles_dict = {}
    for h_list, l_list in handles_labels:
        for h, l in zip(h_list, l_list):
            if l not in handles_dict:
                handles_dict[l] = h

    handles = list(handles_dict.values())
    labels = list(handles_dict.keys())

    if n_plots == 1:
        fig.legend(handles, labels, loc='upper center', ncol=1, bbox_to_anchor=(0.5, 0))
    elif n_plots % 2 == 0:
        fig.subplots_adjust(bottom=0.15)
        fig.legend(handles, labels, loc='lower center', ncol=3, bbox_to_anchor=(0.5, 0.02))
    else:
        # axs[-1].legend(handles, labels, loc='center left', bbox_to_anchor=(1.05, 0.5))
        axs[-1].legend(handles, labels, loc='center', frameon=False)

    fig.tight_layout(rect=[0, 0.08 if n_plots % 2 == 0 else 0, 1, 1], h_pad=1.5)

    output_path = os.path.join("plots", f"{entry['plotPath']}_allMetrics.pdf")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, format="pdf", bbox_inches='tight')
    plt.close()

def main():
    if len(sys.argv) < 2:
        print("Usage: python plotBenchmarks.py <config_path>")
        sys.exit(1)
    config_path = sys.argv[1]
    config = load_config(config_path)
    for entry in config:
        print("Plotting entry")
        plot_data(entry)

if __name__ == "__main__":
    main()