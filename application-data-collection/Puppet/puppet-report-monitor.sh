MaxFileSize=20
#Get size in bytes**
    file_size=`du -b puppet_rpt_conversion.log | tr -s '\t' ' ' | cut -d' ' -f1`
    file_size=$(($file_size/1048576))
    if [ $file_size -gt "$MaxFileSize" ];then   
        timestamp=`date +%s`
        mv puppet_rpt_conversion.log puppet_rpt_conversion.log.$timestamp
    fi
echo "YAML to JSON conversion started!!" 
echo "Start Time: $(date)" 
if [ ! -e last_run_date.tmp ]
then
date "+%Y-%m-%d" --date=1970-01-01 > last_run_date.tmp;
fi
find . -maxdepth 2 -type f -name "*.yaml" -newermt "$(cat last_run_date.tmp)" |
while read f;
do
if [ -s "$f" ]
then
sed 1d "$f" > tmpfile;
ruby -rjson -ryaml -e "resource_list = ''
json = JSON.generate({});data = JSON.parse(json);
obj = JSON.parse(YAML.load_file('tmpfile').to_json);
data['host'] = obj['host'];
data['time'] = obj['time'];
data['configuration_version'] = obj['configuration_version'];
data['transaction_uuid'] = obj['transaction_uuid'];
data['report_format'] = obj['report_format'];
data['puppet_version'] = obj['puppet_version'];
data['status'] = obj['status'];
data['transaction_completed'] = obj['transaction_completed'];
data['noop'] = obj['noop'];
data['noop_pending'] = obj['noop_pending'];
data['environment'] = obj['environment'];
data['metrics'] = obj['metrics'];
data['resource_list'] = resource_list;
i = 0;
obj['resource_statuses'].each{
  |j|
if i == 0 then
  tempdata = j[0];
else
  tempdata = ',' + j[0];
end
data['resource_list'] << tempdata;
i = i + 1;
};

puts data.to_json;
obj['resource_statuses'].each{
  |y|  logsres = y[1];
  logsres['transaction_uuid'] = obj['transaction_uuid'];
  logsres['environment'] = obj['environment'];
  logsres['host'] = obj['host'];
  puts logsres.to_json;
  };
obj['logs'].each {
  |x|logsjson = x;
  logsjson['host'] = obj['host'];
  logsjson['transaction_uuid'] = obj['transaction_uuid'];
  logsjson['environment'] = obj['environment'];
  puts logsjson.to_json
  };"
echo "$f conversion status:" $? 
date "+%d-%b-%Y %H:%M:%S" > last_run_date.tmp
fi
done
echo "Conversion Completed. End Time: $(date)" 