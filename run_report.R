# English ----


# This code will run the national report and save it to the reports folder
# The path options should point to where your data is stored on your computer
# If you want to save the plots as jpeg, set save_plots_to_jpg to TRUE

rmarkdown::render('mobility_viz_report_E.rmd', params = list(
    google_path = "",
    apple_path = "",
    facebook_path = "",
    save_plots_to_jpg = FALSE
    ),
    output_file = paste0("reports/mobility_viz_report-E-", Sys.Date()),
    output_format = "html_document"
)

# This code will run the local authority report and save it to the reports folder
# The path options should point to where your data is stored on your computer

rmarkdown::render('local_authority_report_E.rmd', params = list(
    google_path = ""
    ),
    output_file = paste0("reports/local_authority_report-E-", Sys.Date()),
    output_format = "html_document"
)

# Cymraeg ----

# Defnyddio y cod yma i osod yr iaith i'r Gymraeg
Sys.setlocale(locale = "Welsh")

rmarkdown::render('mobility_viz_report_W.rmd', params = list(
    google_path = "",
    apple_path = "",
    facebook_path = "",
    save_plots_to_jpg = FALSE
    ),
    output_file = paste0("reports/mobility_viz_report-W-", Sys.Date()),
    output_format = "html_document"
    )

rmarkdown::render('local_authority_report_W.rmd', params = list(
    google_path = ""
    ),
    output_file = paste0("reports/local_authority_report-W-", Sys.Date()),
    output_format = "html_document"
    )

# Defnyddio y cod yma i osod yr iaith i Saesneg
Sys.setlocale(locale = "English_United Kingdom")
