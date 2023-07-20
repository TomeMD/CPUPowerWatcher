from my_parser import create_parser
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
import warnings
from datetime import datetime, timedelta
from influxdb_client import InfluxDBClient
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import PolynomialFeatures
from matplotlib.dates import DateFormatter, MinuteLocator
from influxdb_client.client.warnings import MissingPivotFunction

influxdb_url = "http://montoxo.des.udc.es:8086"
influxdb_token = "MyToken"
influxdb_org = "MyOrg"
influxdb_bucket = "glances"

degree = 2

load_query = '''
    from(bucket: "{influxdb_bucket}") 
        |> range(start: {start_date}, stop: {stop_date}) 
        |> filter(fn: (r) => r["_measurement"] == "percpu")
        |> filter(fn: (r) => r["_field"] == "user" )
        |> aggregateWindow(every: 2s, fn: mean, createEmpty: false)
        |> group(columns: ["_measurement"])  
        |> aggregateWindow(every: 2s, fn: sum, createEmpty: false)
        |> yield(name: "sum")'''

energy_query = '''
    from(bucket: "{influxdb_bucket}") 
        |> range(start: {start_date}, stop: {stop_date}) 
        |> filter(fn: (r) => r["_measurement"] == "ENERGY_PACKAGE")
        |> filter(fn: (r) => r["_field"] == "rapl:::PACKAGE_ENERGY:PACKAGE0(J)" or r["_field"] == "rapl:::PACKAGE_ENERGY:PACKAGE1(J)")
        |> aggregateWindow(every: 2s, fn: sum, createEmpty: false)
        |> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
        |> map(fn: (r) => ({{
            _time: r._time, 
            host: r.host, 
            _measurement: r._measurement, 
            _field: "total_energy", 
            _value: (if exists r["rapl:::PACKAGE_ENERGY:PACKAGE0(J)"] then r["rapl:::PACKAGE_ENERGY:PACKAGE0(J)"] else 0.0)
                 + (if exists r["rapl:::PACKAGE_ENERGY:PACKAGE1(J)"] then r["rapl:::PACKAGE_ENERGY:PACKAGE1(J)"] else 0.0)
        }}))'''

def parse_timestamps(file_name):
    with open(file_name, 'r') as f:
        lines = f.readlines()
    timestamps = []
    for i in range(0, len(lines), 2):
        start_line = lines[i]
        stop_line = lines[i+1]
        start_str = " ".join(start_line.split(" ")[-2:]).strip()
        stop_str = " ".join(stop_line.split(" ")[-2:]).strip()
        if (start_line.split(" ")[1] == "STRESS-TEST"): # Stress test CPU consumption
            start = datetime.strptime(start_str, '%Y-%m-%d %H:%M:%S%z') + timedelta(seconds=20)
        elif  (start_line.split(" ")[1] == "CUSTOM"):
            start = datetime.strptime(start_str, '%Y-%m-%d %H:%M:%S%z') + timedelta(seconds=20)
        else: 
            start = datetime.strptime(start_str, '%Y-%m-%d %H:%M:%S%z')
        stop = datetime.strptime(stop_str, '%Y-%m-%d %H:%M:%S%z')
        timestamps.append((start, stop))
    return timestamps

def query_influxdb(query, start_date, stop_date):
    client = InfluxDBClient(url=influxdb_url, token=influxdb_token, org=influxdb_org)
    query_api = client.query_api()
    query = query.format(start_date=start_date, stop_date=stop_date, influxdb_bucket=influxdb_bucket)
    result = query_api.query_data_frame(query)
    return result

def remove_outliers(df, column):
    Q1 = df[column].quantile(0.25)
    Q3 = df[column].quantile(0.75)
    IQR = Q3 - Q1
    lower_bound = Q1 - 1.5 * IQR
    upper_bound = Q3 + 1.5 * IQR
    df_filtered = df[(df[column] >= lower_bound) & (df[column] <= upper_bound)]
    
    return df_filtered

def get_experiment_data(start_date, stop_date):
    load_df = query_influxdb(load_query, start_date, stop_date)
    energy_df = query_influxdb(energy_query, start_date, stop_date)
    load_df_filtered = remove_outliers(load_df, "_value")
    energy_df_filtered = remove_outliers(energy_df, "_value")
    ec_cpu_df = pd.merge(load_df_filtered, energy_df_filtered, on="_time", suffixes=("_load", "_energy"))
    ec_cpu_df = ec_cpu_df[["_time", "_value_load", "_value_energy"]]
    ec_cpu_df.dropna(inplace=True)

    return ec_cpu_df

def plot_time_series(df, title, xlabel, ylabel1, ylabel2, path):
    plt.figure()
    fig, ax1 = plt.subplots()
    ax2 = ax1.twinx()

    # Set CPU Utilization axis
    sns.lineplot(x=df["_time"], y=df["_value_load"], label="Utilización de CPU", ax=ax1)
    ax1.set_xlabel(xlabel)
    ax1.set_ylabel(ylabel1)
    ax1.tick_params(axis='y')
    for label in ax1.get_xticklabels():
        label.set_rotation(45)
    
    # Set Energy Consumption axis
    sns.lineplot(x=df["_time"], y=df["_value_energy"], label="Consumo energético", ax=ax2, color='tab:orange')
    ax2.set_ylabel(ylabel2)
    ax2.tick_params(axis='y')
    ax2.set_ylim(0, 1000)

    # Set time axis
    plt.title(title)
    ax1.xaxis.set_major_locator(MinuteLocator(interval=10))
    ax1.xaxis.set_major_formatter(DateFormatter('%H:%M'))

    # Set legend
    lines1, labels1 = ax1.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    lines = lines1 + lines2
    labels = labels1 + labels2
    ax1.legend(lines, labels, loc='upper left')
    ax2.get_legend().remove()

    plt.tight_layout()
    plt.savefig(path)


def show_model_performance(name, expected, predicted):
    print(f"Modelo: {name}")
    print(f"Mean squared error: {mean_squared_error(expected, predicted)}")
    print(f"R2 score: {r2_score(expected, predicted)}")
    print("")

def plot_lin_regression(model, X, y):
    plt.plot(X, y, color="blue", linewidth=2, label="Regresión lineal")
    m = model.coef_[0]  # Coefficient (slope)
    b = model.intercept_  # Intercept (constant)
    return f"y = {b[0]:.4f} + {m[0]:.4f}x\n"

def plot_poly_regression(model, X, y):
    X_idx = X[:, 1].argsort()
    X_sorted = X[X_idx]
    y_sorted = y[X_idx]
    plt.plot(X_sorted[:, 1], y_sorted, color="red", linewidth=2, label="Regresión polinómica")
    m = model.coef_
    b = model.intercept_ 
    eq = f"y = {b[0]:.4f}"
    for i, c in enumerate(m[0][1:]):
        eq += f" + {c:.8f}x^{i+1}"
    eq+= "\n"
    return eq

if __name__ == '__main__':
    
    parser = create_parser()
    args = parser.parse_args()

    f_train_timestamps = args.train_timestamps
    f_actual_values = args.actual_values
    model_name = args.name
    regression_plot_path = args.regression_plot_path
    data_plot_path = args.data_plot_path

    warnings.simplefilter("ignore", MissingPivotFunction)

    # Get train data
    experiment_dates = parse_timestamps(f_train_timestamps) # Get timestamps from log file
    train_df = pd.DataFrame(columns=["_time", "_value_load", "_value_energy"])
    for start_date, stop_date in experiment_dates:
        experiment_data = get_experiment_data(start_date.strftime("%Y-%m-%dT%H:%M:%SZ"), stop_date.strftime("%Y-%m-%dT%H:%M:%SZ"))
        train_df = pd.concat([train_df, experiment_data], ignore_index=True)

    # Plot train data
    plot_time_series(train_df, "Utilización de CPU y consumo energético", 
                     "Tiempo (HH:MM)", "Utilización de CPU (%)", "Consumo energético (J)", data_plot_path)
    
    # Split into train and test data
    X = train_df["_value_load"].values.reshape(-1, 1)
    y = train_df["_value_energy"].values.reshape(-1, 1)
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    poly_features = PolynomialFeatures(degree=degree)
    X_poly_train = poly_features.fit_transform(X_train)
    X_poly_test = poly_features.transform(X_test)

    # Train models
    lin_reg = LinearRegression()
    poly_reg = LinearRegression()
    lin_reg.fit(X_train, y_train)
    poly_reg.fit(X_poly_train, y_train)

    y_pred = lin_reg.predict(X_test)
    y_poly_pred = poly_reg.predict(X_poly_test)

    # Get actual values if provided
    X_actual = y_actual = None
    if f_actual_values is not None:
        test_dates = parse_timestamps(f_actual_values)
        test_df = pd.DataFrame(columns=["_time", "_value_load", "_value_energy"])
        for start_date, stop_date in test_dates:
            experiment_data = get_experiment_data(start_date.strftime("%Y-%m-%dT%H:%M:%SZ"), stop_date.strftime("%Y-%m-%dT%H:%M:%SZ"))
            test_df = pd.concat([test_df, experiment_data], ignore_index=True)
        X_actual = test_df["_value_load"].values.reshape(-1, 1)
        y_actual = test_df["_value_energy"].values.reshape(-1, 1)


    # Plot model
    plt.figure()
    plt.scatter(X_test, y_test, color="grey", label="Datos de test")
    if (X_actual is not None and y_actual is not None):
        plt.scatter(X_actual, y_actual, color="green", label="Datos reales")
    title = ""
    title += plot_lin_regression(lin_reg, X_test, y_pred)
    title += plot_poly_regression(poly_reg, X_poly_test, y_poly_pred)
    plt.title(title)
    plt.xlabel("Utilización de CPU (%)")
    plt.ylabel("Consumo energético (J)")
    plt.legend()
    plt.tight_layout()
    plt.savefig(regression_plot_path)

    # If actual values are provided they are used to test the model
    if (X_actual is not None and y_actual is not None):
        y_test = y_actual
        X_poly_actual = poly_features.transform(X_actual)
        y_pred = lin_reg.predict(X_actual)
        y_poly_pred = poly_reg.predict(X_poly_actual)

    show_model_performance(f"{model_name} (Regresión lineal)", y_test, y_pred)
    show_model_performance(f"{model_name} (Regresión polinómica)", y_test, y_poly_pred)

