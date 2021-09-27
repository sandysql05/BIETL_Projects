import sys  # For simplicity, we'll read config file from 1st CLI param sys.argv[1]
import json
import logging
import pandas as pd
import requests
import msal
import time
import datetime

# Optional logging
# logging.basicConfig(level=logging.DEBUG)  # Enable DEBUG log for entire script
# logging.getLogger("msal").setLevel(logging.INFO)  # Optionally disable MSAL DEBUG logs

config = json.load(open(sys.argv[1]))
#config = json.load(open(r'C:\Users\sgondela\Documents\GitHub\Enterprise%20Data%20Management\Reporting\PowerBI\PowerBI Usage Metrics\DataExtract\parameters.json'))
Base_Endpoint = "https://api.powerbi.com/v1.0/myorg/admin/"


startdate = datetime.date.today()-datetime.timedelta(4) #extracts data for past two days
enddate = datetime.date.today()-datetime.timedelta(1)

dates = pd.date_range(start=startdate, end=enddate)

for day in dates:
    FileName = 'UsersActivity_' + day.strftime("%Y-%m-%d") #time.strftime("%Y%m%d")

    #region Generate Token Layer
    # Create a preferably long-lived app instance which maintains a token cache.
    app = msal.ConfidentialClientApplication(
        config["client_id"], authority=config["authority"],
        client_credential=config["secret"],
        # token_cache=...  # Default cache is in memory only.
                           # You can learn how to use SerializableTokenCache from
                           # https://msal-python.readthedocs.io/en/latest/#msal.SerializableTokenCache
        )

    # The pattern to acquire a token looks like this.
    result = None

    # Firstly, looks up a token from cache
    # Since we are looking for token for the current app, NOT for an end user,
    # notice we give account parameter as None.
    result = app.acquire_token_silent(config["scope"], account=None)

    #print('second try'+result['access_token'])


    if not result:
        logging.info("No suitable token exists in cache. Let's get a new one from AAD.")
        result = app.acquire_token_for_client(scopes=config["scope"])
    print("access Token: "+result['access_token'])

    #endregion



    #region User Activity Data Extract Layer
    if "access_token" in result:
        continuationToken = ""
        loopcount = 0
        Token = ""
        data = {}
        FinalActivity_data = []
        while 1 == 1:

            if loopcount == 0:
                #print("entering zero loopcount")
                Token = result['access_token']
                UserActivity_Endpoint = Base_Endpoint+"activityevents?startDateTime='" + day.strftime("%Y-%m-%d") + "T00%3A55%3A00.000Z'&endDateTime='" + day.strftime("%Y-%m-%d") +"T23%3A55%3A00.000Z'"
                # "https://api.powerbi.com/v1.0/myorg/admin/activityevents?startDateTime='2021-07-01T00%3A00%3A00.000Z'&endDateTime='2021-07-01T11%3A00%3A00.000Z'"
                print("Extracting Data with uri: "+UserActivity_Endpoint)
            else:
                #print("entering else loopcount")
                UserActivity_Endpoint = Base_Endpoint+"activityevents?continuationToken='" + Token + "'"

            #print(UserActivity_Endpoint)
            data = requests.get(  # Use token to call downstream service
                UserActivity_Endpoint,
                headers={'Authorization': 'Bearer ' + result['access_token']}, ).json()

            Token = data.get('continuationToken')
            FinalActivity_data.append(data.get('activityEventEntities'))

            #print("continuationToken", data.get('continuationToken'), "Token: ", Token, "  after API call", str(loopcount))

            loopcount = loopcount + 1

            # print(data)

            if data.get('continuationToken') == None:  # or Token is 'None':# or  data.get('lastResultSet') == "True":
                break

        with open(config["DataLogsFileShare"] + FileName +  '.txt', 'w') as outfile:
            json.dump(FinalActivity_data, outfile)
        # endregion

    else:
        print(result.get("error"))
        print(result.get("error_description"))
        print(result.get("correlation_id"))  # You may need this when reporting a bug
