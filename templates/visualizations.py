import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go


PRIMARY_COLOR = "#3B6EAD"
SECONDARY_COLOR = "#D9D9D9"

# how to call 
# import sys
# import plotly

# sys.path.append("..")

# from templates.visualizations import (
#     my_bar_plot,
#     my_line_plot,
#     my_scatter_plot
# )


def apply_style(
    fig: go.Figure,
    title: str,
    x_title: str,
    y_title: str
) -> go.Figure:

    fig.update_layout(
        title=title,
        xaxis_title=x_title,
        yaxis_title=y_title,
        legend_title="",
        plot_bgcolor="white",
        paper_bgcolor="white",
        font=dict(size=13),
        title_x=0.5
    )

    fig.update_xaxes(
        showgrid=False,
        linecolor="#BFBFBF"
    )

    fig.update_yaxes(
        gridcolor="#EAEAEA",
        linecolor="#BFBFBF"
    )

    return fig

# reusable bar chart

def my_bar_plot(
    df: pd.DataFrame,
    x_col: str,
    y_col: str,
    title: str = None,
    aggregation: str = "sum",
    highlight: str = "max"
) -> go.Figure:

    if aggregation == "sum":
        df_plot = (
            df.groupby(x_col, as_index=False)[y_col]
            .sum()
        )

    elif aggregation == "mean":
        df_plot = (
            df.groupby(x_col, as_index=False)[y_col]
            .mean()
        )

    elif aggregation == "count":
        df_plot = (
            df.groupby(x_col, as_index=False)[y_col]
            .count()
        )

    else:
        df_plot = df[[x_col, y_col]].copy()


    if highlight == "max":
        flagged_value = df_plot.loc[
            df_plot[y_col].idxmax(),
            x_col
        ]

        label = "Highest"

    else:
        flagged_value = df_plot.loc[
            df_plot[y_col].idxmin(),
            x_col
        ]

        label = "Lowest"


    df_plot["highlight"] = np.where(
        df_plot[x_col] == flagged_value,
        label,
        "Other"
    )


    fig = px.bar(
        df_plot,
        x=x_col,
        y=y_col,
        color="highlight",
        text_auto=".2s",
        color_discrete_map={
            label: PRIMARY_COLOR,
            "Other": SECONDARY_COLOR
        }
    )

    fig.update_traces(
        textposition="outside"
    )

    if title is None:
        title = f"{y_col.replace('_', ' ').title()} by {x_col.replace('_', ' ').title()}"

    return apply_style(
        fig,
        title,
        x_col.replace("_", " ").title(),
        y_col.replace("_", " ").title()
    )

# usage

# fig = my_bar_plot(
#     segment_summary,
#     x_col="Segment_Name",
#     y_col="Total_Revenue",
#     aggregation=None,
#     title="Revenue by RFM Segment"
# )

# fig.show()


# reusable line chart

def my_line_plot(
    df: pd.DataFrame,
    x_col: str,
    y_col: str,
    title: str = None
) -> go.Figure:

    df_plot = df.sort_values(x_col)

    fig = px.line(
        df_plot,
        x=x_col,
        y=y_col,
        markers=True
    )

    fig.update_traces(
        line=dict(width=3)
    )

    if title is None:
        title = f"{y_col.replace('_', ' ').title()} Over Time"

    return apply_style(
        fig,
        title,
        x_col.replace("_", " ").title(),
        y_col.replace("_", " ").title()
    )

# usage

# fig = my_line_plot(
#     monthly_revenue,
#     "date",
#     "revenue_usd",
#     "Monthly Realized Revenue"
# )

# fig.show()

# Scatter plot

def my_scatter_plot(
    df: pd.DataFrame,
    x_col: str,
    y_col: str,
    color_col: str = None,
    title: str = None
) -> go.Figure:

    fig = px.scatter(
        df,
        x=x_col,
        y=y_col,
        color=color_col,
        opacity=0.7
    )

    if title is None:
        title = (
            f"{y_col.replace('_', ' ').title()} vs "
            f"{x_col.replace('_', ' ').title()}"
        )

    return apply_style(
        fig,
        title,
        x_col.replace("_", " ").title(),
        y_col.replace("_", " ").title()
    )

# usage

# fig = my_scatter_plot(
#     rfm,
#     "Frequency",
#     "Monetary",
#     color_col="Segment_Name"
# )

# fig.show()

# Histogram

def my_histogram(
    df: pd.DataFrame,
    col: str,
    bins: int = 30,
    title: str = None
) -> go.Figure:

    fig = px.histogram(
        df,
        x=col,
        nbins=bins
    )

    fig.update_traces(
        marker_color=PRIMARY_COLOR
    )

    if title is None:
        title = f"Distribution of {col.replace('_', ' ').title()}"

    return apply_style(
        fig,
        title,
        col.replace("_", " ").title(),
        "Count"
    )

# usage

# fig = my_histogram(
#     delivered_orders,
#     "total_amount_usd",
#     bins=40
# )

# fig.show()