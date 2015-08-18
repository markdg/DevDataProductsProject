from careerjet_api_client import CareerjetAPIClient
import time, json
from config import affid, user_ip, url

cj  =  CareerjetAPIClient("en_GB");

locations = ['africa', 'asia', 'australia', 'europe', 'north america', 'south america']

for loc in locations:
	result_json = cj.search({
	                        'location'    : loc,
	                        'keywords'    : 'data scientist',
	                        'sort'        : 'salary',
	                        'affid'       : affid,
	                        'user_ip'     : user_ip,
	                        'url'         : url,
	                        'user_agent'  : 'Mozilla/5.0 (X11; Linux x86_64; rv:31.0) Gecko/20100101 Firefox/31.0'
	                      });
	
	with open(loc + '.json', 'w') as outfile:
	    json.dump(result_json, outfile)
	
	time.sleep(20)
	
