using CSV, DataFrames, HTTP, PlotlyJS
using Dash, DashHtmlComponents, DashCoreComponents

## Load COVID-19/Heat data
filename = "Covid-19_Heat_combined_survey.csv"
absolute_path = joinpath(pwd(), "data", filename)
df_CH = DataFrames.DataFrame(CSV.read(absolute_path, DataFrame))

# Get all column names
available_indicators = unique(names(df_CH))

app = dash()

app.layout = html_div() do
    html_div(
        children = [
            dcc_dropdown(
                id = "xaxis-column",
                options = [
                    (label = i, value = i) for i in available_indicators
                ],
                value = "Country",
            ),
        ],
        style = (width = "48%", display = "inline-block"),
    ),
    html_div(
        children = [
            dcc_dropdown(
                id = "yaxis-column",
                options = [
                    (label = i, value = i) for i in available_indicators
                ],
                value = "Gender",
            ),
        ],
        style = (width = "48%", display = "inline-block", float = "right"),
    ),
    dcc_graph(id = "indicator-graphic")
end

callback!(
    app,
    Output("indicator-graphic", "figure"),
    Input("xaxis-column", "value"),
    Input("yaxis-column", "value"),
    #Input("xaxis-type", "value"),
    #Input("yaxis-type", "value")
) do xaxis_column_name, yaxis_column_name#, xaxis_type, yaxis_type

    # Plot the data as bar chart
    column_x = xaxis_column_name
    column_y = yaxis_column_name
    y_unique = unique(df_CH[!, column_y])

    # Group all combinations from the two columns
    df_count = DataFrame(x = Any[], y = Any[], groupcount = Int64[])
    for (key, subdf) in pairs(groupby(df_CH, [column_x, column_y]))
        #println("Number of data points for $(key[column_x]) - $(key[column_y]): $(nrow(subdf))")
        push!(df_count, [key[column_x], key[column_y], nrow(subdf)])
    end

    y_unique = unique(df_count[!, :y])

    # Make categorical to reorder
    #if haskey(reorder_categories, column_x)
    #    df_count[!, :x] = CategoricalArray(df_count[!, :x])
        #levels!(df_count[!,:x], reorder_categories[column_x])
    #end

    # Unstack for side-by-side bar chart
    df3=unstack(df_count, [:x], :y, :groupcount)

    return PlotlyJS.plot(
        #[bar(df3, x=:x, y=y, name=String(y)) for y in [:FEMALE, :MALE]],
        [bar(df3, x=:x, y=Symbol(y), name=String(y)) for y in y_unique],
        #x, y,
        #Layout(
        #    xaxis=attr(type=xaxis_type, title_text=xaxis_column_name),
        #    yaxis=attr(type=yaxis_type, title_text=yaxis_column_name),
        #),
        #text = df2f[
        #    df2f[!, Symbol("Indicator Name")] .== yaxis_column_name,
        #    Symbol("Country Name"),
        #],
        #mode = "markers",
        #marker=attr(size = 15, opacity=0.5, line=attr(width=0.5, color="white"))
    )
end

run_server(app, "0.0.0.0", debug = true)
