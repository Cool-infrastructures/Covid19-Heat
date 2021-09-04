using CSV, DataFrames, HTTP, PlotlyJS
using Dash, DashHtmlComponents, DashCoreComponents

## Load COVID-19/Heat data
filename = "Covid-19_Heat_combined_survey.csv"
absolute_path = joinpath(pwd(), "data", filename)
df_all = DataFrames.DataFrame(CSV.read(absolute_path, DataFrame))

# Change all numbers to strings
df_all = string.(df_all);

# Get all column names
available_indicators = unique(names(df_all))

# Country options
country_options = [
    Dict("label" => "Cameroon", "value" => "Cameroon"),
    Dict("label" => "India", "value" => "India"),
    Dict("label" => "Indonesia", "value" => "Indonesia"),
    Dict("label" => "Pakistan", "value" => "Pakistan"),
]

app = dash()

app.layout = html_div() do
    html_label("Country selector"),
    dcc_checklist(options = country_options, value = ["Cameroon"], id ="country_selector"),

    html_div(
        children = [
            html_label("Base response"),
            dcc_dropdown(
                id = "xaxis-column",
                options = [
                    (label = i, value = i) for i in available_indicators
                ],
                value = "Country",
            ),
            html_label("Base category 1 (multi select)"),
            dcc_dropdown(
                id = "base_cat1",
                options = [
                    (label = i, value = i) for i in unique(df_all[!, :Country])
                ],
                value = unique(df_all[!, :Country])[1],
                multi = true,
            ),
            html_label("Base category 2 (multi select)"),
            dcc_dropdown(
                id = "base_cat2",
                options = [
                    (label = i, value = i) for i in unique(df_all[!, :Country])
                ],
                value = unique(df_all[!, :Country])[end],
                multi = true,
            )
        ],
        style = (width = "48%", display = "inline-block"),
    ),
    html_div(
        children = [
            html_label("Comparison response"),
            dcc_dropdown(
                id = "yaxis-column",
                options = [
                    (label = i, value = i) for i in available_indicators
                ],
                value = "Gender",
            ),
            html_label("Comparison category 1 (multi select)"),
            dcc_dropdown(
                id = "comparison_cat1",
                options = [
                    (label = i, value = i) for i in unique(df_all[!, :Gender])
                ],
                value = unique(df_all[!, :Gender])[1],
                multi = true,
            ),
            html_label("Comparison category 2 (multi select)"),
            dcc_dropdown(
                id = "comparison_cat2",
                options = [
                    (label = i, value = i) for i in unique(df_all[!, :Gender])
                ],
                value = unique(df_all[!, :Gender])[end],
                multi = true,
            )
        ],
        style = (width = "48%", display = "inline-block", float = "right"),
    ),
    html_hr(),
    html_div(
        children = [
            dcc_graph(id = "histogram_count")
        ],
        style = (width = "48%", display = "inline-block", float = "left"),
    ),
    html_div(
        children = [
            dcc_graph(id = "histogram_percentage")
        ],
        style = (width = "48%", display = "inline-block", float = "right"),
    )
end

callback!(
    app,
    Output("histogram_count", "figure"),
    Output("histogram_percentage", "figure"),
    Input("xaxis-column", "value"),
    Input("yaxis-column", "value"),
    Input("country_selector", "value"),
) do xaxis_column_name, yaxis_column_name, countries

    # Filter the selected countries
    df_CH = filter(row -> row.Country in countries, df_all);

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

    return fig1, fig2
end

run_server(app, "0.0.0.0", debug = true)
