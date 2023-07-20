import argparse
from argparse import RawTextHelpFormatter

def create_parser():
    parser = argparse.ArgumentParser(description="Modeling CPU power consumption from InfluxDB time series.", formatter_class=RawTextHelpFormatter)

    parser.add_argument(
        "-t",
        "--train-timestamps",
        default="log/stress.timestamps",
        help="File storing time series timestamps from train data. By default is log/stress.timestamps. Timestamps must be stored in the following format:\n \
    <EXP-NAME> <TYPE-OF-EXPERIMENT> ... <DATE-START>\n \
    <EXP-NAME> <TYPE-OF-EXPERIMENT> ... <DATE-STOP>\n \
Example:\n \
    Spread_P&L STRESS-TEST (cores = 0,16) start: 2023-04-18 14:26:01+0000\n \
    Spread_P&L STRESS-TEST (cores = 0,16) stop: 2023-04-18 14:28:01+0000",
    )

    parser.add_argument(
        "-a",
        "--actual-values",
        default=None,
        help="File storing time series timestamps from actual values of load and energy to test the model (in same format as train timestamps). If not specified train data will be split into train and test data.\n\
Timestamps must be stored in the same format as train timestamps.",
    )

    parser.add_argument(
        "-n",
        "--name",
        default="EC-CPU-MODEL",
        help="Name of the model. It is useful to generate models from different sets of experiments in an orderly manner. By default is 'EC-CPU-MODEL'",
    )

    parser.add_argument(
        "-r",
        "--regression-plot-path",
        default="img/regression.png",
        help="Specifies the path to save the regression plot. By default is 'img/regression.png'.",
    )

    parser.add_argument(
        "-d",
        "--data-plot-path",
        default="img/data.png",
        help="Specifies the path to save the data plot. By default is 'img/data.png'.",
    )

    return parser
