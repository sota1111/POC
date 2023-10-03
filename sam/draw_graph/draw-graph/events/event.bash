sam local invoke "UploadPlotFunction" -e events/event_upload.json
sam local invoke "DataListFunction" -e events/event_get_data.json
# base64 -i plot_data/sin_wave.csv -o plot_data/encoded_sin_wave.txt
