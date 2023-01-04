#!/bin/bash

for a in ood_desktop ood_jupyter ood_vscode ood_rstudio ood_wheel; do
    find /var/log/ondemand-nginx -name "error*" | xargs zgrep ${a} > ${a}.log
    grep pjsub  ${a}.log > ${a}.pjsub.log
    grep sbatch ${a}.log > ${a}.sbatch.log
done

filename=/var/www/ood/public/ana.html
cat <<EOF > $filename
<!DOCTYPE html>
<html>
  <head>
    <title>Number of application launches</title>
    <meta charset="UTF-8">
    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
      google.charts.load('current', {'packages':['bar']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {
        var fugaku_data = google.visualization.arrayToDataTable([
          ['Year-Month', 'Remote Desktop', 'Jupyter', 'Rstudio', 'VSCode', 'Wheel'],
EOF

d="2022-09-01"
today=`date "+%Y-%m-%d"`
while [[ "$d" < $today ]]; do
    month=`echo $d | awk -F- '{print $1"-"$2}'`
    desktop=`grep ${month} ood_desktop.pjsub.log | wc -l`
    jupyter=`grep ${month} ood_jupyter.pjsub.log | wc -l`
    vscode=`grep ${month} ood_vscode.pjsub.log | wc -l`
    rstudio=`grep ${month} ood_rstudio.pjsub.log | wc -l`
    wheel=`grep ${month} ood_wheel.pjsub.log | wc -l`
    echo "['$month', $desktop, $jupyter, $vscode, $rstudio, $wheel]," >> $filename
    d=$(date +%F -d "$d 1 month")
done

cat <<EOF >> $filename
        ]);
	var prepost_data = google.visualization.arrayToDataTable([
          ['Year-Month', 'Remote Desktop', 'Jupyter', 'Rstudio', 'VSCode', 'Wheel'],
EOF
d="2022-09-01"
today=`date "+%Y-%m-%d"`
while [[ "$d" < $today ]]; do
    month=`echo $d | awk -F- '{print $1"-"$2}'`
    desktop=`grep ${month} ood_desktop.sbatch.log | wc -l`
    jupyter=`grep ${month} ood_jupyter.sbatch.log | wc -l`
    vscode=`grep ${month} ood_vscode.sbatch.log | wc -l`
    rstudio=`grep ${month} ood_rstudio.sbatch.log | wc -l`
    wheel=`grep ${month} ood_wheel.sbatch.log | wc -l`
    echo "['$month', $desktop, $jupyter, $vscode, $rstudio, $wheel]," >> $filename
    d=$(date +%F -d "$d 1 month")
done

cat <<EOF >> $filename
        ]);

        var fugaku_options = {
          chart: {
              title: 'Fugaku',
	      subtitle: 'Number of application launches'
          },
	  bars: 'horizontal',
        };

        var prepost_options = {
          chart: {
              title: 'Prepost',
              subtitle: 'Number of application launches'
          },
          bars: 'horizontal',
        };

 	var fugaku_chart = new google.charts.Bar(document.getElementById('fugaku_barchart_material'));
        var prepost_chart = new google.charts.Bar(document.getElementById('prepost_barchart_material'));	
        fugaku_chart.draw(fugaku_data, google.charts.Bar.convertOptions(fugaku_options));
        prepost_chart.draw(prepost_data, google.charts.Bar.convertOptions(prepost_options));
      }
    </script>
  </head>
  <body>
    <table border="1" bordercolor="#333333" cellpadding="10" cellspacing="0">
      <tr>
        <td>
          <div id="fugaku_barchart_material" style="width: 800px; height: 500px;"></div>
        </td>
        <td>
          <div id="prepost_barchart_material" style="width: 800px; height: 500px;"></div>	
        </td>
      </tr>
    </table>
  </body>
</html>
EOF

for a in ood_desktop ood_jupyter ood_vscode ood_rstudio ood_wheel; do
    rm -f ${a}.log ${a}.pjsub.log ${a}.sbatch.log
done
