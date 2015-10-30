Scalable spatial-temporal BFAST
=================

Reproduction of the computations on the article "Spatio-Temporal Change Detection from Multidimensional Arrays: detecting deforestation from MODIS time series"


<h3>Files:</h3>
<ul>
	<li><code>LICENSE</code> - License file.</li>
	<li><code>README.md</code> - This file.</li>
	<li>Docker files:
		<ul>
			<li><code>Dockerfile</code> - Script for building a Docker Image.</li>
			<li><code>setup.sh</code> - Host script for removing former containers and images from host machine. Then, it creates a Docker image called "scidb_img".</li>
		</ul>
	</li>
	<li>Container files:
		<ul>
      <li><code>containerSetup.sh</code> - Script for setting up SciDB. Then it runs the experiment.</li>
      <li><code>createArray.afl</code> - Array Functional Language script for creating an array to store MODIS data.</li>
      <li><code>downloaddata.sh</code> - Script for downloading MODIS data.</li>
      <li><code>removeArrayVersions.sh</code> - Script for removing array's versions.</li>

      <li>SciDB configuration files:
        <ul>
          <li><code>conf</code> - SHIM configuration file. Shim is a web service that allows to query SciDB.</li>
    			<li><code>iquery.conf</code> - IQUERY configuration file.</li>
    			<li><code>scidb_docker.ini</code> - SciDB's configuration file.</li>
          <li><code>setEnvironment.sh</code> - Script for setting environment variables for SciDB's users.</li>
          <li><code>startScidb.sh</code> - Script for starting SciDB.</li>
          <li><code>stopScidb.sh</code> - Script for stopping SciDB.</li>
        </ul>
      </li>

      <li>Install additional software:
        <ul>
          <li><code>installBoost_1570.sh</code> - Script for installing the Boost libraries.</li>
          <li><code>installGribModis2SciDB.sh</code> - Script for installing the tool which export MODIS data to SciDB's binary.</li>
          <li><code>installPackages.R</code> - R script for installing R packages.</li>
          <li><code>installParallel.sh</code> - Script for installing GNU Parallel.</li>
          <li><code>installR.sh</code> - Script for installing R.</li>
          <li><code>libr_exec.so</code> - Precompiled <i>r_exec</i> library for SciDB.</li>
        </ul>
      </li>

      <li>Scripts for running the expriement:
        <ul>
          <li><code>reprosarefp.R</code> - .</li>
          <li><code>rexec_sar_efp_f.R</code> - .</li>
          </ul>
        </li>

		</ul>
	</li>
</ul>



<h3>Pre-requisites:</h3>
  <ul>
    <li>Internet access</li>
    <li>Docker.io</li>
  <li>SSH</li>
</ul>



<h3>Instructions:</h3>
<ol>
	<li>Clone the project and then go to the cloned folder: <code>git clone https://github.com/ifgi/scalable-spatial-temporal-BFAST.git</code></li>
	<li>Modify the configuration file <em>scidb_docker.ini</em> according to your needs and your hardware.</li>
	<li>Enable <code>setup.sh</code> for execution <code>chmod +x setup.sh</code> and run it <code>./setup.sh</code>. This creates a new Docker image from the Dockerfile and then starts a container.</li>
	<li>Log into the container: <code>ssh -p 49905 root@localhost</code>. The default password is <em>xxxx.xxxx.xxxx</em></li>
	<li>Execute the script <code>/root/./containerSetup.sh</code>. This script sets SciDB, downloads MODIS data to SciDB, and finally executes the experiment.</li>
</ol>
