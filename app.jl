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
            dcc_graph(id = "histogram_count"),
            dcc_graph(id = "histogram_percentage_xaxis"),
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
            dcc_graph(id = "histogram_percentage")
        ],
        style = (width = "48%", display = "inline-block", float = "right"),
    )
end

callback!(
    app,
    Output("histogram_count", "figure"),
    Output("histogram_percentage", "figure"),
    Output("histogram_percentage_xaxis", "figure"),  
    Input("xaxis-column", "value"),
    Input("yaxis-column", "value"),
    #Input("xaxis-type", "value"),
    #Input("yaxis-type", "value")
) do xaxis_column_name, yaxis_column_name#, xaxis_type, yaxis_type

    # Plot the data as bar chart
    column_x = xaxis_column_name
    column_y = yaxis_column_name
    y_unique = unique(df_CH[!, column_y])

    # Calculate column_x group sizes
    df_x = DataFrame(x = Any[], groupcount=Int64[])
    for (key, subdf) in pairs(groupby(df_CH, [column_x]))
        #println("Number of data points for $(key[column_x]): $(nrow(subdf))")
        push!(df_x, [key[column_x], nrow(subdf)])
    end

    # Calculate column_y group sizes
    df_y = DataFrame(x = Any[], groupcount=Int64[])
    for (key, subdf) in pairs(groupby(df_CH, [column_y]))
        #println("Number of data points for $(key[column_y]): $(nrow(subdf))")
        push!(df_y, [key[column_y], nrow(subdf)])
    end
   
    # Group all combinations from the two columns
    df2 = DataFrame(x = Any[], y = Any[], groupcount = Int64[], grouppercentage = Float64[], xaxis_percentage = Float64[], percentage = Float64[])
    for (key, subdf) in pairs(groupby(df_CH, [column_x, column_y]))
        #println("Number of data points for $(key[column_x]) - $(key[column_y]): $(nrow(subdf)) - $(100*nrow(subdf)/df_y[df_y.x .== key[column_y], :groupcount][1]) - $(100*nrow(subdf)/nrow(df_CH))")
        push!(df2, [key[column_x], key[column_y], nrow(subdf), 100*nrow(subdf)/df_y[df_y.x .== key[column_y], :groupcount][1], 100*nrow(subdf)/df_x[df_x.x .== key[column_x], :groupcount][1], 100*nrow(subdf)/nrow(df_CH)])
    end

    y_unique = unique(df2[!, :y])

    # Make categorical to reorder
    #if haskey(reorder_categories, column_x)
    #    df_count[!, :x] = CategoricalArray(df_count[!, :x])
        #levels!(df_count[!,:x], reorder_categories[column_x])
    #end

    # Unstack for side-by-side bar chart
    df3=unstack(df2, [:x], :y, :groupcount)
    df4=unstack(df2, [:x], :y, :grouppercentage)
    df5=unstack(df2, [:x], :y, :percentage)
    df6=unstack(df2, [:x], :y, :xaxis_percentage)    

    fig1 = PlotlyJS.plot(
        [bar(df3, x=:x, y=Symbol(y), name=String(y)) for y in y_unique],
        Layout(
            xaxis=attr(title_text=xaxis_column_name),
            yaxis=attr(title_text="Count"),
            title=attr(text="Number of $(yaxis_column_name) responses grouped by $(xaxis_column_name)"),
        ),
    )

    fig3 = PlotlyJS.plot(
        [bar(df5, x=:x, y=Symbol(y), name=String(y)) for y in y_unique],
        Layout(
            xaxis=attr(title_text=xaxis_column_name),
            yaxis=attr(title_text="Percentage of all responses"),
            title=attr(text="Percentage of all survey responses"),
        ),
    )

    fig2 = PlotlyJS.plot(
        [bar(df6, x=:x, y=Symbol(y), name=String(y)) for y in y_unique],
        Layout(
            xaxis=attr(title_text=xaxis_column_name),
            yaxis=attr(title_text="Percentage of categories on x axis"),
            title=attr(text="Percentage of $(yaxis_column_name) responses grouped by $(xaxis_column_name)"),
        ),
    )

    return fig1, fig2, fig3
end

run_server(app, "0.0.0.0", debug = true)
