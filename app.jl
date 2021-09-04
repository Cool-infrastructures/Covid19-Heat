using CSV, DataFrames, HTTP, PlotlyJS
using Dash, DashHtmlComponents, DashCoreComponents
using HypothesisTests

# Function to calculate the statistics
function calc_statistics(df_tmp, base, base_categories, comp, comp_categories, print_flag=false)
    total_number = size(df_tmp)[1]
    # Generate empty arrays for the statistic calculation
    num_second = zeros(Int64, 2)
    df_second = []

    # Extract the two categories and calculate the numbers in each
    for i = 1:2
        push!(df_second, filter(row -> row[comp] in comp_categories[i], df_tmp))
        num_second[i] = size(df_second[i])[1]
    end

    # Generate the matrix for the chi^2 test
    num_array = zeros(Int64, 2, 2)
    for i = 1:2
        for j = 1:2
            #num_array[i, j] = size(filter(row -> row.TemperatureInsideHome in base.Categories[i], df_second[j]))[1]
            num_array[i, j] = size(filter(row -> row[base] in base_categories[i], df_second[j]))[1]
        end
    end

    # Calculate the Chi^2 value
    result = ChisqTest(num_array)
    chi_sq = round(result.stat, digits=3)
    p_value = pvalue(result)
    perc_comp1 = round((num_array[1,1] + num_array[2,1])/total_number*100, digits=2)
    perc_comp1_base1 = round(num_array[1,1]/total_number*100, digits=2)
    
    # Odds ratio and 95% confidence interval
    odds_ratio = round((num_array[1,1]/num_array[2,1]) / (num_array[1,2]/num_array[2,2]), digits=3)
    upper95 = round(exp(log(odds_ratio) + 1.96 * sqrt(1/num_array[1,1] + 1/num_array[2,1] + 1/num_array[1,2] +1/num_array[2,2])), digits=3)
    lower95 = round(exp(log(odds_ratio) - 1.96 * sqrt(1/num_array[1,1] + 1/num_array[2,1] + 1/num_array[1,2] +1/num_array[2,2])), digits=3)
    
    # Print for checking
    if print_flag
        println("Base case: ", base)
        println("\tCategory 1: ", string(base_categories[1])) 
        println("\tCategory 2: ", string(base_categories[2]))
        println(comp, ":")
        println("\t", num_second[1], " (", perc_comp1, "%) in Category 1: ", string(comp_categories[1]))
        println("\t", num_second[2], " (", 100 - perc_comp1, "%) in Category 2: ", string(comp_categories[2]))
        println("Data array: ", num_array)
        println("Chi^2 = ", chi_sq, ", p-value = ", p_value)
        println("Odds ratio = ", odds_ratio, ", CI: ", lower95, "-", upper95, "\n")
    end

    return chi_sq, p_value, odds_ratio, lower95, upper95, perc_comp1, perc_comp1_base1, num_array
end


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
app.title = "COVID-19/Heat survey"

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
        style = (width = "50%", display = "inline-block", float = "left"),
    ),
    html_div(
        children = [
            dcc_graph(id = "histogram_percentage")
        ],
        style = (width = "50%", display = "inline-block", float = "right"),
    ),
    html_hr(),
    html_div(id = "stats-values"),
    html_p(
        children = [
            html_hr(),
            html_label("The presented data is from the SFC-GCRF COVID-19/Heat Urgency grant and can be found at https://github.com/Cool-infrastructures/Covid19-Heat")
        ])
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

# Update the category dropdown menues for the base response
callback!(
    app,
    Output("base_cat1", "options"),
    Output("base_cat1", "value"),
    Output("base_cat2", "options"),
    Output("base_cat2", "value"),
    Input("xaxis-column", "value"),
) do selected_base
    categories = [(label = i, value = i) for i in unique(df_all[!, selected_base])]
    return categories, [categories[1].value], categories, [categories[end].value]
end

# Update the category dropdown menues for the comparison response
callback!(
    app,
    Output("comparison_cat1", "options"),
    Output("comparison_cat1", "value"),
    Output("comparison_cat2", "options"),
    Output("comparison_cat2", "value"),
    Input("yaxis-column", "value"),
) do selected_comparison
    categories = [(label = i, value = i) for i in unique(df_all[!, selected_comparison])]
    return categories, [categories[1].value], categories, [categories[end].value]
end

# Calculate and print the statistics values
callback!(
    app,
    Output("stats-values", "children"),
    Input("xaxis-column", "value"),
    Input("base_cat1", "value"), 
    Input("base_cat2", "value"), 
    Input("yaxis-column", "value"),
    Input("comparison_cat1", "value"), 
    Input("comparison_cat2", "value"), 
    Input("country_selector", "value"),
) do base, base_cat1, base_cat2, comp, comp_cat1, comp_cat2, countries
    cat1 = Vector{String}()
    for i in comp_cat1
        push!(cat1, i)
    end

    cat2 = Vector{String}()
    for i in comp_cat2
        push!(cat2, i)
    end

    comp_categories = [cat1, cat2]

    cat1 = Vector{String}()
    for i in base_cat1
        push!(cat1, i)
    end

    cat2 = Vector{String}()
    for i in base_cat2
        push!(cat2, i)
    end

    base_categories = [cat1, cat2]

    # Filter the selected countries
    df_CH = filter(row -> row.Country in countries, df_all);

    chi_sq, p_value, odds_ratio, lower95, upper95, perc_comp1, perc_comp1_base1, num_array = calc_statistics(df_CH, base, base_categories, comp, comp_categories, false)

    significant = "not statistically significant"
    # Check significance for lowre odds ratio
    if (lower95 < 1.0 && upper95 < 1.0) 
        significant = "statistically significant and the odds ratio is lower"
    end
    # Check significance for higher odds ratio
    if (lower95 > 1.0 && upper95 > 1.0)
        significant = "statistically significant and the odds ratio is higher"
    end    


    return "The odds to report $(base) of $(base_cat1) is $(odds_ratio) for respondents in $(comp) - $(comp_cat1) compared to $(comp) - $(comp_cat2). The result is $(significant)."
end

run_server(app, "0.0.0.0", debug = true)
