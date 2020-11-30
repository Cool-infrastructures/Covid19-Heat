# Covid19-Heat
Analyse the data from the Covid-19/Heat nexus survey

## Overview of the notebooks

- Generate_individual_plots.ipynb is a Julia notebook to generate individual histograms for any column in the datasets and graphs showing the combination of two columns

## Running of the notebooks

### Use the free binder service

You can use the free binder service by clicking at the following link:
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/Cool-infrastructures/Covid19-Heat/HEAD)

However, this is a free service and can be slow.

### Install Julia and run the notebooks on your computer

I will describe all steps necessary to do this but, briefly, we need to install Julia with a few extra packages and start the notebook service.

1. Download Julia for your operating system from https://julialang.org/downloads/
2. Install it on your computer
3. Start Julia and press ] once it is started
4. This step will take at least several minutes so it is a good time to get a coffee or go for a walk once you have pressed enter. Copy the following text into the programme window and press enter:

        add IJulia, CSV, DataFrames, Plots, StatsPlots, StatsBase, DataStructures; precompile

5. Once it is finished press Backspace, copy the following text into the programme window and press enter:

        using IJulia

    Press y if asked about the installation of conda which will also take some time.
        
6. Now we can start the jupyter notebook service by entering the following text into the programme and afterwards pressing enter:

        using IJulia; notebook()

7. This should open a website in your browser which shows your home folder. After you have done all these steps once, the next time you only need to start Julia and perform step 6. to get the service running.
8. Now you need to download the project files. To do this, you click on the green 'Code' button on this website (https://github.com/Cool-infrastructures/Covid19-Heat/) and select 'Download ZIP'.
9. Once the zip file is downloaded you have to extract it somewhere in your home folder.
10. Now you can go back to the jupyter notebook service running in your browser, open the project folder you just extracted and click on Generate_individual_plots.ipynb to start the notebook.
11. If you have made it this far, you can select 'Run All' in the 'Cell' menu to run the complete notebook.
12. After some time (the first run is always a bit slow) you should see a few plots. Feel free to change the column names for the histogram and scatter plots. You can't break anything. The worst that can happen is that you have to redownload the code.
