daniel@goldenlinux:~$ ssh t1221an@maccluster
Last login: Sun Jan 11 12:41:10 2015 from 226.193.eduroam.dynamic.rbg.tum.de
------------------------------------------------------------------------------
                                                       ##########   ##########
   Welcome to the MAC Research Cluster                    ##   ##   ##  ##  ##
              operated by                                 ##   ##   ##  ##  ##
     Leibniz Supercomputing Centre                        ##   ##   ##  ##  ##
                                                          ##   #######  ##  ##
------------------------------------------------------------------------------

This cluster offers several different platforms organized as partitions:

PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
nvd          up   infinite      4   idle mac-nvd[01-04]
ati          up   infinite      4   idle mac-ati[01-04]
wsm          up   infinite      2   idle mac-wsm[01-02]
snb          up   infinite     28   idle mac-snb[01-28]
bdz          up   infinite     19   idle mac-bdz[01-19]

NodeName=mac-nvd[01-04] Procs=32 Sockets=2 CoresPerSocket=8 ThreadsPerCore=2
NodeName=mac-ati[01-04] Procs=32 Sockets=2 CoresPerSocket=8 ThreadsPerCore=2
NodeName=mac-wsm[01-02] Procs=64 Sockets=4 CoresPerSocket=8 ThreadsPerCore=2
NodeName=mac-snb[01-28] Procs=32 Sockets=2 CoresPerSocket=8 ThreadsPerCore=2
NodeName=mac-bdz[01-19] Procs=64 Sockets=4 CoresPerSocket=16 ThreadsPerCore=1

partition "nvd" features:
  - 4 nodes: dual socket Intel SandyBridge-EP Xeon E5-2670, 128 GB RAM,
    two NVIDIA M2090 GPUs and FDR infiniband
    
partition "ati" features:
  - 4 nodes: dual socket Intel SandyBridge-EP Xeon E5-2670, 128 GB RAM,
    two AMD FirePro W8000 GPUs and FDR infiniband

partition "wsm" features:
  - 2 nodes: quad socket Intel Westmere-EX Xeon E7-4830, 512 GB RAM and
    FDR infiniband (QDR speed due to PCIe 2.0)
  
partition "snb" features:
  - 28 nodes: dual socket Intel SandyBridge-EP Xeon E5-2670, 128 GB RAM
    and QDR infiniband

partition "bdz" features:
  - 19 nodes: quad socket AMD Bulldozer Opteron 6274, 256 GB RAM
    and QDR infiniband

On Intel processors, Hyperthreading is enabled AND job allocation assumes 
enabled HT!

All nodes within a partition are directly connected 
through one infiniband switch.

There are no direct logins to compute nodes! You have to use interactive 
batch shells or regular batch jobs. For instructions see below!


General Instructions
====================

Please refer to: http://www.lrz.de/services/compute/linux-cluster/

please add following line to your .bashrc in order to activate
LRZ's module system for headless ssh logins (srun, MPI):

source /etc/profile.d/modules.sh

If you want to ssh your compute nodes during a job allocation you
need to setup password-less ssh connections within the LRZ Linux
cluster. For instruction please refer to:
http://www.lrz.de/services/compute/ssh/#TOC6

Please use the module system in order to load compilers and 
standard tools like svn or git.

The some applies for OpenCL by AMD and CUDA. For using OpenCL on
the nvd partition a workaround, described below, is needed.

Interactive Shells
==================

In order to alloc a subset of nodes within a partition, please use
following command (example!):

salloc --partition=snb --ntasks=24 --cpus-per-task=32

In order to examine granted resources you may want to read
following env. variables:

$SLURM_CPUS_PER_TASK      $SLURM_JOB_NODELIST       $SLURM_NPROCS
$SLURM_JOB_CPUS_PER_NODE  $SLURM_JOB_NUM_NODES      $SLURM_NTASKS
$SLURM_JOBID              $SLURM_NNODES             $SLURM_SUBMIT_DIR
$SLURM_JOB_ID             $SLURM_NODELIST           $SLURM_TASKS_PER_NODE

You can assemble a host list by:

scontrol show hostnames ${SLURM_JOB_NODELIST}

In order to run your application please execute:

srun ./a.out

During a job allocation, users are allowed to ssh the corresponding job nodes!

PLEASE NOTE: Automatic Intel MPI rank pinning is not available when using
srun. If your application is sensitive to pinning, please have a have look
on srun --cpu_bind option (man srun)!

PLEASE NOTE: This cluster is operated with Intel Hyperthreading Technology being
enabled. If you intend to use just physical cores for a pure MPI application,
please make sure to specify --cpus-per-task=2. If you want to run
hybrid (OMP + MPI) jobs please adjust --cpus-per-task accordingly!


Batch Operation
===============

Besides interactive shells, we also support regular batch jobs as usage
model.

Please find an example below. This example starts a job with following
settings:

- using partition "snb"
- allocates 8 nodes (as --cpus-per-task=32)
- using Intel MPI with hydra scheduler
     specifying number of threads

------------------------------------------------------------------------------
start SLURM job script
------------------------------------------------------------------------------
#!/bin/bash

#SBATCH -o /home/hpc/<project>/<user>/myjob.%j.out
#SBATCH -D /home/hpc/<project>/<user>
#SBATCH -J myjob
#SBATCH --get-user-env
#SBATCH --partition=snb
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=32
#SBATCH --mail-type=end
#SBATCH --mail-user=user@in.tum.de
#SBATCH --export=NONE
#SBATCH --time=01:30:00

source /etc/profile.d/modules.sh

mpiexec.hydra -genv OMP_NUM_THREADS 16 -ppn 1 -n 8 ./a.out
------------------------------------------------------------------------------
end SLURM job script
------------------------------------------------------------------------------

During a job allocation, users are allowed to ssh the corresponding job nodes!

PLEASE NOTE: This cluster is operated with Intel Hyperthreading Technology being
enabled. If you intend to use just physical cores for a pure MPI application,
please make sure to specify --cpus-per-task=2. If you want to run
hybrid (OMP + MPI) jobs please adjust --cpus-per-task accordingly!


MPI Profiling
=============

Scalasca 1.4.3 was validated with Intel MPI, the Intel Compiler suite and 
the GNU compiler suite on this cluster.

Please download it from here:
http://www.scalasca.org/software/scalasca-1.x/download.html
and perform an installation into $HOME.

You have to build scalasca on mac-login-amd (mac-login-intel has some software
installed that confuses the configure script and therefore the wrong version
of scalasca is built) by following commands:

./configure --prefix=$HOME
make
make install

Furthermore, you need to adjust your .bashrc in order to expand PATH and
LD_LIBRARY_PATH to $HOME/bin and $HOME/lib $HOME/lib64

ATTENTION: application tracing with compiler instrumentation is not
possible due to the lack of a high-performance parallel file system.
Therefore, please DO NOT run scalasca like this: 

scalasca -analyze -t [your mpiexec.hydra call]

unless you have instrumented the your code with

scalasca -insturment -comp=none -mode=MPI (just during linking!!)


Known Issues and News
=====================

- Due to the weird NVIDIA software stack, compiling for NVIDIA OpenCL is
  currently not possible on the login nodes since they do not feature
  NVIDIA GPUs. Please allocate an interactive job and compile against the
  local installation in /usr/local/cuda! This does not apply for CUDA! 
  Please use the module system for CUDA!

- only the Intel toolchain is validated! This includes all Intel
  compilers, Intel MPI, and using the GNU compilers with Intel MPI. 
  Using other compilers (Open64, PGI, etc.) and other 
  MPI implementations (OpenMPI, MVAPICH, etc.)
  are not validated, but may work, however, there is no support converage!

- Turbo mode is ENABLED on snb/ati/nvd-partition; 
  use the --constraint=turbo_off option during jobs submission (salloc, sbatch) 
  for running jobs on the snb/ati/nvd-partition with disabled Turbo! 
  (e.g. in case of speed-up tests)


test
------------------------------------------------------------------------

Home directories are using    95 GB out of   100 GB, 6 GB are available
Scratch directory is using  7059 GB out of 18626 GB, 11567 GB are available

t1221an@mac-login-amd:~> ssh mac-snb16
Last login: Sun Jan 11 12:11:31 2015 from mac-login-amd
test
t1221an@mac-snb16:~> ls
backups          learning  r000hs              swe.tar    vector.c
eclipsews        main      set-environment.sh  timer.c    vector.opt
gauss.c          main.c    slurm_scripts       timer.cod  workingdir
gauss-orgn.c     mbox      src-backup.tar      timer.h
icc-options.txt  mic       swe                 timer.s
intel            number3   swe-meas            vector2.c
t1221an@mac-snb16:~> cd swe-meas/
t1221an@mac-snb16:~/swe-meas> ls
_00.nc       swee-modded.sh   swee-stock2.txt  SWE_intel_release_stock_omp
modded1.txt  swee-stock1.txt  swee-stock.sh    swe-omp-fused-shared
t1221an@mac-snb16:~/swe-meas> ./swee-stock.sh 
./SWE_intel_release_stock_omp: error while loading shared libraries: libnetcdf.so.7: cannot open shared object file: No such file or directory

real	0m0.008s
user	0m0.000s
sys	0m0.000s
./SWE_intel_release_stock_omp: error while loading shared libraries: libnetcdf.so.7: cannot open shared object file: No such file or directory

real	0m0.003s
user	0m0.000s
sys	0m0.000s
./SWE_intel_release_stock_omp: error while loading shared libraries: libnetcdf.so.7: cannot open shared object file: No such file or directory

real	0m0.003s
user	0m0.000s
sys	0m0.000s
./SWE_intel_release_stock_omp: error while loading shared libraries: libnetcdf.so.7: cannot open shared object file: No such file or directory

real	0m0.003s
user	0m0.000s
sys	0m0.000s
./SWE_intel_release_stock_omp: error while loading shared libraries: libnetcdf.so.7: cannot open shared object file: No such file or directory

real	0m0.003s
user	0m0.000s
sys	0m0.000s
t1221an@mac-snb16:~/swe-meas> module load netcdf
t1221an@mac-snb16:~/swe-meas> ./swee-stock.sh 

*************************************************************
Welcome to SWE

SWE Copyright (C) 2012-2013
  Technische Universitaet Muenchen
  Department of Informatics
  Chair of Scientific Computing
  http://www5.in.tum.de/SWE

SWE comes with ABSOLUTELY NO WARRANTY.
SWE is free software, and you are welcome to redistribute it
under certain conditions.
Details can be found in the file 'gpl.txt'.
*************************************************************
Sun Jan 11 13:38:39 2015	Writing output file at time: 0 seconds
                                                                                
------------------------------------------------------------------
Sun Jan 11 13:38:49 2015	Everything is set up, starting the simulation.
------------------------------------------------------------------
Sun Jan 11 13:38:49 2015        Simulation at time: 0.0219831 seconds.          
Sun Jan 11 13:38:49 2015        Simulation at time: 0.0432806 seconds.          
Sun Jan 11 13:38:49 2015        Simulation at time: 0.0642069 seconds.          
Sun Jan 11 13:38:49 2015        Simulation at time: 0.0848982 seconds.          
Sun Jan 11 13:38:49 2015        Simulation at time: 0.105438 seconds.           
Sun Jan 11 13:38:49 2015        Simulation at time: 0.125793 seconds.           
Sun Jan 11 13:38:49 2015        Simulation at time: 0.146023 seconds.           
Sun Jan 11 13:38:49 2015        Simulation at time: 0.166186 seconds.           
Sun Jan 11 13:38:49 2015        Simulation at time: 0.186302 seconds.           
Sun Jan 11 13:38:49 2015        Simulation at time: 0.206399 seconds.           
Sun Jan 11 13:38:49 2015        Simulation at time: 0.226492 seconds.           
Sun Jan 11 13:38:50 2015        Simulation at time: 0.246591 seconds.           
Sun Jan 11 13:38:50 2015        Simulation at time: 0.266673 seconds.           
Sun Jan 11 13:38:50 2015        Simulation at time: 0.286752 seconds.           
Sun Jan 11 13:38:50 2015        Simulation at time: 0.306841 seconds.           
Sun Jan 11 13:38:50 2015        Simulation at time: 0.326948 seconds.           
Sun Jan 11 13:38:50 2015        Simulation at time: 0.347074 seconds.           
Sun Jan 11 13:38:50 2015        Simulation at time: 0.367217 seconds.           
Sun Jan 11 13:38:50 2015        Simulation at time: 0.387362 seconds.           
Sun Jan 11 13:38:50 2015        Simulation at time: 0.407508 seconds.           
Sun Jan 11 13:38:50 2015        Simulation at time: 0.427655 seconds.           
Sun Jan 11 13:38:50 2015        Simulation at time: 0.447803 seconds.           
Sun Jan 11 13:38:51 2015        Simulation at time: 0.467952 seconds.           
Sun Jan 11 13:38:51 2015        Simulation at time: 0.488099 seconds.           
Sun Jan 11 13:38:51 2015        Simulation at time: 0.508247 seconds.           
Sun Jan 11 13:38:51 2015        Simulation at time: 0.528394 seconds.           
Sun Jan 11 13:38:51 2015        Simulation at time: 0.548542 seconds.           
Sun Jan 11 13:38:51 2015        Simulation at time: 0.568689 seconds.           
Sun Jan 11 13:38:51 2015        Simulation at time: 0.588834 seconds.           
Sun Jan 11 13:38:51 2015        Simulation at time: 0.608978 seconds.           
Sun Jan 11 13:38:51 2015        Simulation at time: 0.629122 seconds.           
Sun Jan 11 13:38:51 2015        Simulation at time: 0.649266 seconds.           
Sun Jan 11 13:38:51 2015        Simulation at time: 0.669409 seconds.           
Sun Jan 11 13:38:51 2015        Simulation at time: 0.68955 seconds.            
Sun Jan 11 13:38:52 2015        Simulation at time: 0.70969 seconds.            
Sun Jan 11 13:38:52 2015        Simulation at time: 0.729831 seconds.           
Sun Jan 11 13:38:52 2015        Simulation at time: 0.749971 seconds.           
Sun Jan 11 13:38:52 2015        Simulation at time: 0.770112 seconds.           
Sun Jan 11 13:38:52 2015        Writing output file at time: 0.770112 seconds   
Sun Jan 11 13:39:32 2015        Simulation at time: 0.790251 seconds.           
Sun Jan 11 13:39:32 2015        Simulation at time: 0.810388 seconds.           
Sun Jan 11 13:39:32 2015        Simulation at time: 0.830525 seconds.           
Sun Jan 11 13:39:32 2015        Simulation at time: 0.850662 seconds.           
Sun Jan 11 13:39:32 2015        Simulation at time: 0.870797 seconds.           
Sun Jan 11 13:39:33 2015        Simulation at time: 0.890927 seconds.           
Sun Jan 11 13:39:33 2015        Simulation at time: 0.911055 seconds.           
Sun Jan 11 13:39:33 2015        Simulation at time: 0.931181 seconds.           
Sun Jan 11 13:39:33 2015        Simulation at time: 0.951306 seconds.           
Sun Jan 11 13:39:33 2015        Simulation at time: 0.971428 seconds.           
Sun Jan 11 13:39:33 2015        Simulation at time: 0.991548 seconds.           
Sun Jan 11 13:39:33 2015        Simulation at time: 1.01167 seconds.            
Sun Jan 11 13:39:33 2015        Simulation at time: 1.03178 seconds.            
Sun Jan 11 13:39:33 2015        Simulation at time: 1.0519 seconds.             
Sun Jan 11 13:39:33 2015        Simulation at time: 1.07201 seconds.            
Sun Jan 11 13:39:33 2015        Simulation at time: 1.09212 seconds.            
Sun Jan 11 13:39:34 2015        Simulation at time: 1.11223 seconds.            
Sun Jan 11 13:39:34 2015        Simulation at time: 1.13234 seconds.            
Sun Jan 11 13:39:34 2015        Simulation at time: 1.15245 seconds.            
Sun Jan 11 13:39:34 2015        Simulation at time: 1.17256 seconds.            
Sun Jan 11 13:39:34 2015        Simulation at time: 1.19267 seconds.            
Sun Jan 11 13:39:34 2015        Simulation at time: 1.21277 seconds.            
Sun Jan 11 13:39:34 2015        Simulation at time: 1.23288 seconds.            
Sun Jan 11 13:39:34 2015        Simulation at time: 1.25298 seconds.            
Sun Jan 11 13:39:34 2015        Simulation at time: 1.27309 seconds.            
Sun Jan 11 13:39:34 2015        Simulation at time: 1.29319 seconds.            
Sun Jan 11 13:39:34 2015        Simulation at time: 1.31329 seconds.            
Sun Jan 11 13:39:34 2015        Simulation at time: 1.33339 seconds.            
Sun Jan 11 13:39:35 2015        Simulation at time: 1.35349 seconds.            
Sun Jan 11 13:39:35 2015        Simulation at time: 1.37359 seconds.            
Sun Jan 11 13:39:35 2015        Simulation at time: 1.39368 seconds.            
Sun Jan 11 13:39:35 2015        Simulation at time: 1.41378 seconds.            
Sun Jan 11 13:39:35 2015        Simulation at time: 1.43387 seconds.            
Sun Jan 11 13:39:35 2015        Simulation at time: 1.45397 seconds.            
Sun Jan 11 13:39:35 2015        Simulation at time: 1.47406 seconds.            
Sun Jan 11 13:39:35 2015        Simulation at time: 1.49415 seconds.            
Sun Jan 11 13:39:35 2015        Simulation at time: 1.51424 seconds.            
Sun Jan 11 13:39:35 2015        Writing output file at time: 1.51424 seconds    
Sun Jan 11 13:39:51 2015        Simulation at time: 1.53432 seconds.            
Sun Jan 11 13:39:51 2015        Simulation at time: 1.55441 seconds.            
Sun Jan 11 13:39:51 2015        Simulation at time: 1.5745 seconds.             
Sun Jan 11 13:39:51 2015        Simulation at time: 1.59458 seconds.            
Sun Jan 11 13:39:51 2015        Simulation at time: 1.61466 seconds.            
Sun Jan 11 13:39:51 2015        Simulation at time: 1.63474 seconds.            
Sun Jan 11 13:39:52 2015        Simulation at time: 1.65482 seconds.            
Sun Jan 11 13:39:52 2015        Simulation at time: 1.6749 seconds.             
Sun Jan 11 13:39:52 2015        Simulation at time: 1.69497 seconds.            
Sun Jan 11 13:39:52 2015        Simulation at time: 1.71505 seconds.            
Sun Jan 11 13:39:52 2015        Simulation at time: 1.73512 seconds.            
Sun Jan 11 13:39:52 2015        Simulation at time: 1.75519 seconds.            
Sun Jan 11 13:39:52 2015        Simulation at time: 1.77526 seconds.            
Sun Jan 11 13:39:52 2015        Simulation at time: 1.79533 seconds.            
Sun Jan 11 13:39:52 2015        Simulation at time: 1.8154 seconds.             
Sun Jan 11 13:39:52 2015        Simulation at time: 1.83546 seconds.            
Sun Jan 11 13:39:52 2015        Simulation at time: 1.85553 seconds.            
Sun Jan 11 13:39:53 2015        Simulation at time: 1.87559 seconds.            
Sun Jan 11 13:39:53 2015        Simulation at time: 1.89565 seconds.            
Sun Jan 11 13:39:53 2015        Simulation at time: 1.91571 seconds.            
Sun Jan 11 13:39:53 2015        Simulation at time: 1.93577 seconds.            
Sun Jan 11 13:39:53 2015        Simulation at time: 1.95582 seconds.            
Sun Jan 11 13:39:53 2015        Simulation at time: 1.97588 seconds.            
Sun Jan 11 13:39:53 2015        Simulation at time: 1.99593 seconds.            
Sun Jan 11 13:39:53 2015        Simulation at time: 2.01598 seconds.            
Sun Jan 11 13:39:53 2015        Simulation at time: 2.03603 seconds.            
Sun Jan 11 13:39:53 2015        Simulation at time: 2.05608 seconds.            
Sun Jan 11 13:39:53 2015        Simulation at time: 2.07613 seconds.            
Sun Jan 11 13:39:53 2015        Simulation at time: 2.09617 seconds.            
Sun Jan 11 13:39:54 2015        Simulation at time: 2.11622 seconds.            
Sun Jan 11 13:39:54 2015        Simulation at time: 2.13626 seconds.            
Sun Jan 11 13:39:54 2015        Simulation at time: 2.1563 seconds.             
Sun Jan 11 13:39:54 2015        Simulation at time: 2.17634 seconds.            
Sun Jan 11 13:39:54 2015        Simulation at time: 2.19637 seconds.            
Sun Jan 11 13:39:54 2015        Simulation at time: 2.21641 seconds.            
Sun Jan 11 13:39:54 2015        Simulation at time: 2.23644 seconds.            
Sun Jan 11 13:39:54 2015        Simulation at time: 2.25647 seconds.            
Sun Jan 11 13:39:54 2015        Writing output file at time: 2.25647 seconds    
Sun Jan 11 13:40:08 2015        Simulation at time: 2.2765 seconds.             
Sun Jan 11 13:40:08 2015        Simulation at time: 2.29653 seconds.            
Sun Jan 11 13:40:08 2015        Simulation at time: 2.31656 seconds.            
Sun Jan 11 13:40:08 2015        Simulation at time: 2.33658 seconds.            
Sun Jan 11 13:40:08 2015        Simulation at time: 2.35661 seconds.            
Sun Jan 11 13:40:09 2015        Simulation at time: 2.37663 seconds.            
Sun Jan 11 13:40:09 2015        Simulation at time: 2.39665 seconds.            
Sun Jan 11 13:40:09 2015        Simulation at time: 2.41667 seconds.            
Sun Jan 11 13:40:09 2015        Simulation at time: 2.43668 seconds.            
Sun Jan 11 13:40:09 2015        Simulation at time: 2.4567 seconds.             
Sun Jan 11 13:40:09 2015        Simulation at time: 2.47671 seconds.            
Sun Jan 11 13:40:09 2015        Simulation at time: 2.49672 seconds.            
Sun Jan 11 13:40:09 2015        Simulation at time: 2.51673 seconds.            
Sun Jan 11 13:40:09 2015        Simulation at time: 2.53674 seconds.            
Sun Jan 11 13:40:09 2015        Simulation at time: 2.55675 seconds.            
Sun Jan 11 13:40:09 2015        Simulation at time: 2.57675 seconds.            
Sun Jan 11 13:40:10 2015        Simulation at time: 2.59676 seconds.            
Sun Jan 11 13:40:10 2015        Simulation at time: 2.61676 seconds.            
Sun Jan 11 13:40:10 2015        Simulation at time: 2.63676 seconds.            
Sun Jan 11 13:40:10 2015        Simulation at time: 2.65676 seconds.            
Sun Jan 11 13:40:10 2015        Simulation at time: 2.67675 seconds.            
Sun Jan 11 13:40:10 2015        Simulation at time: 2.69675 seconds.            
Sun Jan 11 13:40:10 2015        Simulation at time: 2.71674 seconds.            
Sun Jan 11 13:40:10 2015        Simulation at time: 2.73674 seconds.            
Sun Jan 11 13:40:10 2015        Simulation at time: 2.75673 seconds.            
Sun Jan 11 13:40:10 2015        Simulation at time: 2.77671 seconds.            
Sun Jan 11 13:40:10 2015        Simulation at time: 2.7967 seconds.             
Sun Jan 11 13:40:10 2015        Simulation at time: 2.81669 seconds.            
Sun Jan 11 13:40:11 2015        Simulation at time: 2.83667 seconds.            
Sun Jan 11 13:40:11 2015        Simulation at time: 2.85665 seconds.            
Sun Jan 11 13:40:11 2015        Simulation at time: 2.87663 seconds.            
Sun Jan 11 13:40:11 2015        Simulation at time: 2.89661 seconds.            
Sun Jan 11 13:40:11 2015        Simulation at time: 2.91659 seconds.            
Sun Jan 11 13:40:11 2015        Simulation at time: 2.93656 seconds.            
Sun Jan 11 13:40:11 2015        Simulation at time: 2.95654 seconds.            
Sun Jan 11 13:40:11 2015        Simulation at time: 2.97651 seconds.            
Sun Jan 11 13:40:11 2015        Simulation at time: 2.99648 seconds.            
Sun Jan 11 13:40:11 2015        Simulation at time: 3.01645 seconds.            
Sun Jan 11 13:40:11 2015        Writing output file at time: 3.01645 seconds    
Sun Jan 11 13:40:31 2015        Simulation at time: 3.03642 seconds.            
Sun Jan 11 13:40:31 2015        Simulation at time: 3.05638 seconds.            
Sun Jan 11 13:40:31 2015        Simulation at time: 3.07634 seconds.            
Sun Jan 11 13:40:31 2015        Simulation at time: 3.09631 seconds.            
Sun Jan 11 13:40:31 2015        Simulation at time: 3.11627 seconds.            
Sun Jan 11 13:40:31 2015        Simulation at time: 3.13623 seconds.            
Sun Jan 11 13:40:31 2015        Simulation at time: 3.15618 seconds.            
Sun Jan 11 13:40:31 2015        Simulation at time: 3.17614 seconds.            
Sun Jan 11 13:40:32 2015        Simulation at time: 3.19609 seconds.            
Sun Jan 11 13:40:32 2015        Simulation at time: 3.21604 seconds.            
Sun Jan 11 13:40:32 2015        Simulation at time: 3.236 seconds.              
Sun Jan 11 13:40:32 2015        Simulation at time: 3.25594 seconds.            
Sun Jan 11 13:40:32 2015        Simulation at time: 3.27589 seconds.            
Sun Jan 11 13:40:32 2015        Simulation at time: 3.29584 seconds.            
Sun Jan 11 13:40:32 2015        Simulation at time: 3.31578 seconds.            
Sun Jan 11 13:40:32 2015        Simulation at time: 3.33572 seconds.            
Sun Jan 11 13:40:32 2015        Simulation at time: 3.35566 seconds.            
Sun Jan 11 13:40:32 2015        Simulation at time: 3.3756 seconds.             
Sun Jan 11 13:40:32 2015        Simulation at time: 3.39554 seconds.            
Sun Jan 11 13:40:33 2015        Simulation at time: 3.41547 seconds.            
Sun Jan 11 13:40:33 2015        Simulation at time: 3.43541 seconds.            
Sun Jan 11 13:40:33 2015        Simulation at time: 3.45534 seconds.            
Sun Jan 11 13:40:33 2015        Simulation at time: 3.47527 seconds.            
Sun Jan 11 13:40:33 2015        Simulation at time: 3.49519 seconds.            
Sun Jan 11 13:40:33 2015        Simulation at time: 3.51512 seconds.            
Sun Jan 11 13:40:33 2015        Simulation at time: 3.53505 seconds.            
Sun Jan 11 13:40:33 2015        Simulation at time: 3.55497 seconds.            
Sun Jan 11 13:40:33 2015        Simulation at time: 3.57489 seconds.            
Sun Jan 11 13:40:33 2015        Simulation at time: 3.59481 seconds.            
Sun Jan 11 13:40:33 2015        Simulation at time: 3.61473 seconds.            
Sun Jan 11 13:40:33 2015        Simulation at time: 3.63464 seconds.            
Sun Jan 11 13:40:34 2015        Simulation at time: 3.65456 seconds.            
Sun Jan 11 13:40:34 2015        Simulation at time: 3.67447 seconds.            
Sun Jan 11 13:40:34 2015        Simulation at time: 3.69438 seconds.            
Sun Jan 11 13:40:34 2015        Simulation at time: 3.71429 seconds.            
Sun Jan 11 13:40:34 2015        Simulation at time: 3.73419 seconds.            
Sun Jan 11 13:40:34 2015        Simulation at time: 3.7541 seconds.             
Sun Jan 11 13:40:34 2015        Writing output file at time: 3.7541 seconds     
Sun Jan 11 13:41:09 2015        Simulation at time: 3.774 seconds.              
Sun Jan 11 13:41:09 2015        Simulation at time: 3.7939 seconds.             
Sun Jan 11 13:41:09 2015        Simulation at time: 3.8138 seconds.             
Sun Jan 11 13:41:09 2015        Simulation at time: 3.8337 seconds.             
Sun Jan 11 13:41:09 2015        Simulation at time: 3.85359 seconds.            
Sun Jan 11 13:41:09 2015        Simulation at time: 3.87349 seconds.            
Sun Jan 11 13:41:09 2015        Simulation at time: 3.89338 seconds.            
Sun Jan 11 13:41:09 2015        Simulation at time: 3.91327 seconds.            
Sun Jan 11 13:41:09 2015        Simulation at time: 3.93316 seconds.            
Sun Jan 11 13:41:09 2015        Simulation at time: 3.95304 seconds.            
Sun Jan 11 13:41:09 2015        Simulation at time: 3.97293 seconds.            
Sun Jan 11 13:41:10 2015        Simulation at time: 3.99281 seconds.            
Sun Jan 11 13:41:10 2015        Simulation at time: 4.01269 seconds.            
Sun Jan 11 13:41:10 2015        Simulation at time: 4.03257 seconds.            
Sun Jan 11 13:41:10 2015        Simulation at time: 4.05245 seconds.            
Sun Jan 11 13:41:10 2015        Simulation at time: 4.07232 seconds.            
Sun Jan 11 13:41:10 2015        Simulation at time: 4.0922 seconds.             
Sun Jan 11 13:41:10 2015        Simulation at time: 4.11207 seconds.            
Sun Jan 11 13:41:10 2015        Simulation at time: 4.13194 seconds.            
Sun Jan 11 13:41:10 2015        Simulation at time: 4.1518 seconds.             
Sun Jan 11 13:41:10 2015        Simulation at time: 4.17167 seconds.            
Sun Jan 11 13:41:10 2015        Simulation at time: 4.19153 seconds.            
Sun Jan 11 13:41:11 2015        Simulation at time: 4.21139 seconds.            
Sun Jan 11 13:41:11 2015        Simulation at time: 4.23125 seconds.            
Sun Jan 11 13:41:11 2015        Simulation at time: 4.25111 seconds.            
Sun Jan 11 13:41:11 2015        Simulation at time: 4.27097 seconds.            
Sun Jan 11 13:41:11 2015        Simulation at time: 4.29082 seconds.            
Sun Jan 11 13:41:11 2015        Simulation at time: 4.31067 seconds.            
Sun Jan 11 13:41:11 2015        Simulation at time: 4.33053 seconds.            
Sun Jan 11 13:41:11 2015        Simulation at time: 4.35037 seconds.            
Sun Jan 11 13:41:11 2015        Simulation at time: 4.37022 seconds.            
Sun Jan 11 13:41:11 2015        Simulation at time: 4.39006 seconds.            
Sun Jan 11 13:41:11 2015        Simulation at time: 4.40991 seconds.            
Sun Jan 11 13:41:11 2015        Simulation at time: 4.42975 seconds.            
Sun Jan 11 13:41:12 2015        Simulation at time: 4.44959 seconds.            
Sun Jan 11 13:41:12 2015        Simulation at time: 4.46943 seconds.            
Sun Jan 11 13:41:12 2015        Simulation at time: 4.48926 seconds.            
Sun Jan 11 13:41:12 2015        Simulation at time: 4.50909 seconds.            
Sun Jan 11 13:41:12 2015        Writing output file at time: 4.50909 seconds    
Sun Jan 11 13:41:46 2015        Simulation at time: 4.52893 seconds.            
Sun Jan 11 13:41:46 2015        Simulation at time: 4.54876 seconds.            
Sun Jan 11 13:41:46 2015        Simulation at time: 4.56858 seconds.            
Sun Jan 11 13:41:47 2015        Simulation at time: 4.58841 seconds.            
Sun Jan 11 13:41:47 2015        Simulation at time: 4.60823 seconds.            
Sun Jan 11 13:41:47 2015        Simulation at time: 4.62806 seconds.            
Sun Jan 11 13:41:47 2015        Simulation at time: 4.64788 seconds.            
Sun Jan 11 13:41:47 2015        Simulation at time: 4.6677 seconds.             
Sun Jan 11 13:41:47 2015        Simulation at time: 4.68751 seconds.            
Sun Jan 11 13:41:47 2015        Simulation at time: 4.70733 seconds.            
Sun Jan 11 13:41:47 2015        Simulation at time: 4.72714 seconds.            
Sun Jan 11 13:41:47 2015        Simulation at time: 4.74695 seconds.            
Sun Jan 11 13:41:47 2015        Simulation at time: 4.76676 seconds.            
Sun Jan 11 13:41:47 2015        Simulation at time: 4.78657 seconds.            
Sun Jan 11 13:41:47 2015        Simulation at time: 4.80638 seconds.            
Sun Jan 11 13:41:48 2015        Simulation at time: 4.82618 seconds.            
Sun Jan 11 13:41:48 2015        Simulation at time: 4.84598 seconds.            
Sun Jan 11 13:41:48 2015        Simulation at time: 4.86578 seconds.            
Sun Jan 11 13:41:48 2015        Simulation at time: 4.88558 seconds.            
Sun Jan 11 13:41:48 2015        Simulation at time: 4.90538 seconds.            
Sun Jan 11 13:41:48 2015        Simulation at time: 4.92517 seconds.            
Sun Jan 11 13:41:48 2015        Simulation at time: 4.94497 seconds.            
Sun Jan 11 13:41:48 2015        Simulation at time: 4.96476 seconds.            
Sun Jan 11 13:41:48 2015        Simulation at time: 4.98455 seconds.            
Sun Jan 11 13:41:48 2015        Simulation at time: 5.00434 seconds.            
Sun Jan 11 13:41:48 2015        Simulation at time: 5.02412 seconds.            
Sun Jan 11 13:41:49 2015        Simulation at time: 5.04391 seconds.            
Sun Jan 11 13:41:49 2015        Simulation at time: 5.06369 seconds.            
Sun Jan 11 13:41:49 2015        Simulation at time: 5.08348 seconds.            
Sun Jan 11 13:41:49 2015        Simulation at time: 5.10325 seconds.            
Sun Jan 11 13:41:49 2015        Simulation at time: 5.12303 seconds.            
Sun Jan 11 13:41:49 2015        Simulation at time: 5.14281 seconds.            
Sun Jan 11 13:41:49 2015        Simulation at time: 5.16259 seconds.            
Sun Jan 11 13:41:49 2015        Simulation at time: 5.18236 seconds.            
Sun Jan 11 13:41:49 2015        Simulation at time: 5.20213 seconds.            
Sun Jan 11 13:41:49 2015        Simulation at time: 5.2219 seconds.             
Sun Jan 11 13:41:49 2015        Simulation at time: 5.24167 seconds.            
Sun Jan 11 13:41:49 2015        Simulation at time: 5.26144 seconds.            
Sun Jan 11 13:41:49 2015        Writing output file at time: 5.26144 seconds    
Sun Jan 11 13:41:56 2015        Simulation at time: 5.2812 seconds.             
Sun Jan 11 13:41:56 2015        Simulation at time: 5.30097 seconds.            
Sun Jan 11 13:41:56 2015        Simulation at time: 5.32073 seconds.            
Sun Jan 11 13:41:56 2015        Simulation at time: 5.34049 seconds.            
Sun Jan 11 13:41:56 2015        Simulation at time: 5.36025 seconds.            
Sun Jan 11 13:41:56 2015        Simulation at time: 5.38001 seconds.            
Sun Jan 11 13:41:56 2015        Simulation at time: 5.39976 seconds.            
Sun Jan 11 13:41:56 2015        Simulation at time: 5.41952 seconds.            
Sun Jan 11 13:41:57 2015        Simulation at time: 5.43927 seconds.            
Sun Jan 11 13:41:57 2015        Simulation at time: 5.45902 seconds.            
Sun Jan 11 13:41:57 2015        Simulation at time: 5.47877 seconds.            
Sun Jan 11 13:41:57 2015        Simulation at time: 5.49852 seconds.            
Sun Jan 11 13:41:57 2015        Simulation at time: 5.51827 seconds.            
Sun Jan 11 13:41:57 2015        Simulation at time: 5.53801 seconds.            
Sun Jan 11 13:41:57 2015        Simulation at time: 5.55775 seconds.            
Sun Jan 11 13:41:57 2015        Simulation at time: 5.5775 seconds.             
Sun Jan 11 13:41:57 2015        Simulation at time: 5.59724 seconds.            
Sun Jan 11 13:41:57 2015        Simulation at time: 5.61698 seconds.            
Sun Jan 11 13:41:57 2015        Simulation at time: 5.63672 seconds.            
Sun Jan 11 13:41:57 2015        Simulation at time: 5.65645 seconds.            
Sun Jan 11 13:41:58 2015        Simulation at time: 5.67619 seconds.            
Sun Jan 11 13:41:58 2015        Simulation at time: 5.69592 seconds.            
Sun Jan 11 13:41:58 2015        Simulation at time: 5.71566 seconds.            
Sun Jan 11 13:41:58 2015        Simulation at time: 5.73539 seconds.            
Sun Jan 11 13:41:58 2015        Simulation at time: 5.75512 seconds.            
Sun Jan 11 13:41:58 2015        Simulation at time: 5.77485 seconds.            
Sun Jan 11 13:41:58 2015        Simulation at time: 5.79458 seconds.            
Sun Jan 11 13:41:58 2015        Simulation at time: 5.8143 seconds.             
Sun Jan 11 13:41:58 2015        Simulation at time: 5.83403 seconds.            
Sun Jan 11 13:41:58 2015        Simulation at time: 5.85375 seconds.            
Sun Jan 11 13:41:58 2015        Simulation at time: 5.87347 seconds.            
Sun Jan 11 13:41:59 2015        Simulation at time: 5.89319 seconds.            
Sun Jan 11 13:41:59 2015        Simulation at time: 5.91291 seconds.            
Sun Jan 11 13:41:59 2015        Simulation at time: 5.93263 seconds.            
Sun Jan 11 13:41:59 2015        Simulation at time: 5.95235 seconds.            
Sun Jan 11 13:41:59 2015        Simulation at time: 5.97207 seconds.            
Sun Jan 11 13:41:59 2015        Simulation at time: 5.99178 seconds.            
Sun Jan 11 13:41:59 2015        Simulation at time: 6.01149 seconds.            
Sun Jan 11 13:41:59 2015        Writing output file at time: 6.01149 seconds    
Sun Jan 11 13:42:05 2015        Simulation at time: 6.03121 seconds.            
Sun Jan 11 13:42:05 2015        Simulation at time: 6.05092 seconds.            
Sun Jan 11 13:42:05 2015        Simulation at time: 6.07063 seconds.            
Sun Jan 11 13:42:05 2015        Simulation at time: 6.09034 seconds.            
Sun Jan 11 13:42:05 2015        Simulation at time: 6.11005 seconds.            
Sun Jan 11 13:42:05 2015        Simulation at time: 6.12975 seconds.            
Sun Jan 11 13:42:05 2015        Simulation at time: 6.14946 seconds.            
Sun Jan 11 13:42:05 2015        Simulation at time: 6.16916 seconds.            
Sun Jan 11 13:42:05 2015        Simulation at time: 6.18887 seconds.            
Sun Jan 11 13:42:05 2015        Simulation at time: 6.20857 seconds.            
Sun Jan 11 13:42:05 2015        Simulation at time: 6.22827 seconds.            
Sun Jan 11 13:42:05 2015        Simulation at time: 6.24797 seconds.            
Sun Jan 11 13:42:06 2015        Simulation at time: 6.26767 seconds.            
Sun Jan 11 13:42:06 2015        Simulation at time: 6.28737 seconds.            
Sun Jan 11 13:42:06 2015        Simulation at time: 6.30707 seconds.            
Sun Jan 11 13:42:06 2015        Simulation at time: 6.32677 seconds.            
Sun Jan 11 13:42:06 2015        Simulation at time: 6.34646 seconds.            
Sun Jan 11 13:42:06 2015        Simulation at time: 6.36616 seconds.            
Sun Jan 11 13:42:06 2015        Simulation at time: 6.38585 seconds.            
Sun Jan 11 13:42:06 2015        Simulation at time: 6.40555 seconds.            
Sun Jan 11 13:42:06 2015        Simulation at time: 6.42524 seconds.            
Sun Jan 11 13:42:06 2015        Simulation at time: 6.44493 seconds.            
Sun Jan 11 13:42:06 2015        Simulation at time: 6.46462 seconds.            
Sun Jan 11 13:42:07 2015        Simulation at time: 6.48431 seconds.            
Sun Jan 11 13:42:07 2015        Simulation at time: 6.504 seconds.              
Sun Jan 11 13:42:07 2015        Simulation at time: 6.52369 seconds.            
Sun Jan 11 13:42:07 2015        Simulation at time: 6.54338 seconds.            
Sun Jan 11 13:42:07 2015        Simulation at time: 6.56307 seconds.            
Sun Jan 11 13:42:07 2015        Simulation at time: 6.58276 seconds.            
Sun Jan 11 13:42:07 2015        Simulation at time: 6.60244 seconds.            
Sun Jan 11 13:42:07 2015        Simulation at time: 6.62213 seconds.            
Sun Jan 11 13:42:07 2015        Simulation at time: 6.64181 seconds.            
Sun Jan 11 13:42:07 2015        Simulation at time: 6.6615 seconds.             
Sun Jan 11 13:42:07 2015        Simulation at time: 6.68118 seconds.            
Sun Jan 11 13:42:07 2015        Simulation at time: 6.70087 seconds.            
Sun Jan 11 13:42:08 2015        Simulation at time: 6.72055 seconds.            
Sun Jan 11 13:42:08 2015        Simulation at time: 6.74023 seconds.            
Sun Jan 11 13:42:08 2015        Simulation at time: 6.75991 seconds.            
Sun Jan 11 13:42:08 2015        Writing output file at time: 6.75991 seconds    
Sun Jan 11 13:42:14 2015        Simulation at time: 6.7796 seconds.             
Sun Jan 11 13:42:14 2015        Simulation at time: 6.79928 seconds.            
Sun Jan 11 13:42:14 2015        Simulation at time: 6.81896 seconds.            
Sun Jan 11 13:42:14 2015        Simulation at time: 6.83864 seconds.            
Sun Jan 11 13:42:14 2015        Simulation at time: 6.85832 seconds.            
Sun Jan 11 13:42:14 2015        Simulation at time: 6.878 seconds.              
Sun Jan 11 13:42:14 2015        Simulation at time: 6.89768 seconds.            
Sun Jan 11 13:42:14 2015        Simulation at time: 6.91736 seconds.            
Sun Jan 11 13:42:14 2015        Simulation at time: 6.93704 seconds.            
Sun Jan 11 13:42:14 2015        Simulation at time: 6.95672 seconds.            
Sun Jan 11 13:42:15 2015        Simulation at time: 6.9764 seconds.             
Sun Jan 11 13:42:15 2015        Simulation at time: 6.99608 seconds.            
Sun Jan 11 13:42:15 2015        Simulation at time: 7.01576 seconds.            
Sun Jan 11 13:42:15 2015        Simulation at time: 7.03544 seconds.            
Sun Jan 11 13:42:15 2015        Simulation at time: 7.05512 seconds.            
Sun Jan 11 13:42:15 2015        Simulation at time: 7.0748 seconds.             
Sun Jan 11 13:42:15 2015        Simulation at time: 7.09448 seconds.            
Sun Jan 11 13:42:15 2015        Simulation at time: 7.11416 seconds.            
Sun Jan 11 13:42:15 2015        Simulation at time: 7.13384 seconds.            
Sun Jan 11 13:42:15 2015        Simulation at time: 7.15352 seconds.            
Sun Jan 11 13:42:15 2015        Simulation at time: 7.1732 seconds.             
Sun Jan 11 13:42:16 2015        Simulation at time: 7.19288 seconds.            
Sun Jan 11 13:42:16 2015        Simulation at time: 7.21256 seconds.            
Sun Jan 11 13:42:16 2015        Simulation at time: 7.23225 seconds.            
Sun Jan 11 13:42:16 2015        Simulation at time: 7.25193 seconds.            
Sun Jan 11 13:42:16 2015        Simulation at time: 7.27161 seconds.            
Sun Jan 11 13:42:16 2015        Simulation at time: 7.29129 seconds.            
Sun Jan 11 13:42:16 2015        Simulation at time: 7.31098 seconds.            
Sun Jan 11 13:42:16 2015        Simulation at time: 7.33066 seconds.            
Sun Jan 11 13:42:16 2015        Simulation at time: 7.35035 seconds.            
Sun Jan 11 13:42:16 2015        Simulation at time: 7.37003 seconds.            
Sun Jan 11 13:42:16 2015        Simulation at time: 7.38972 seconds.            
Sun Jan 11 13:42:16 2015        Simulation at time: 7.4094 seconds.             
Sun Jan 11 13:42:17 2015        Simulation at time: 7.42909 seconds.            
Sun Jan 11 13:42:17 2015        Simulation at time: 7.44878 seconds.            
Sun Jan 11 13:42:17 2015        Simulation at time: 7.46847 seconds.            
Sun Jan 11 13:42:17 2015        Simulation at time: 7.48816 seconds.            
Sun Jan 11 13:42:17 2015        Simulation at time: 7.50785 seconds.            
Sun Jan 11 13:42:17 2015        Writing output file at time: 7.50785 seconds    
Sun Jan 11 13:42:23 2015        Simulation at time: 7.52754 seconds.            
Sun Jan 11 13:42:23 2015        Simulation at time: 7.54724 seconds.            
Sun Jan 11 13:42:23 2015        Simulation at time: 7.56693 seconds.            
Sun Jan 11 13:42:23 2015        Simulation at time: 7.58663 seconds.            
Sun Jan 11 13:42:23 2015        Simulation at time: 7.60632 seconds.            
Sun Jan 11 13:42:23 2015        Simulation at time: 7.62602 seconds.            
Sun Jan 11 13:42:23 2015        Simulation at time: 7.64572 seconds.            
Sun Jan 11 13:42:23 2015        Simulation at time: 7.66542 seconds.            
Sun Jan 11 13:42:23 2015        Simulation at time: 7.68512 seconds.            
Sun Jan 11 13:42:23 2015        Simulation at time: 7.70483 seconds.            
Sun Jan 11 13:42:23 2015        Simulation at time: 7.72453 seconds.            
Sun Jan 11 13:42:23 2015        Simulation at time: 7.74424 seconds.            
Sun Jan 11 13:42:24 2015        Simulation at time: 7.76395 seconds.            
Sun Jan 11 13:42:24 2015        Simulation at time: 7.78366 seconds.            
Sun Jan 11 13:42:24 2015        Simulation at time: 7.80337 seconds.            
Sun Jan 11 13:42:24 2015        Simulation at time: 7.82309 seconds.            
Sun Jan 11 13:42:24 2015        Simulation at time: 7.8428 seconds.             
Sun Jan 11 13:42:24 2015        Simulation at time: 7.86252 seconds.            
Sun Jan 11 13:42:24 2015        Simulation at time: 7.88224 seconds.            
Sun Jan 11 13:42:24 2015        Simulation at time: 7.90197 seconds.            
Sun Jan 11 13:42:24 2015        Simulation at time: 7.92169 seconds.            
Sun Jan 11 13:42:24 2015        Simulation at time: 7.94142 seconds.            
Sun Jan 11 13:42:24 2015        Simulation at time: 7.96115 seconds.            
Sun Jan 11 13:42:24 2015        Simulation at time: 7.98088 seconds.            
Sun Jan 11 13:42:25 2015        Simulation at time: 8.00062 seconds.            
Sun Jan 11 13:42:25 2015        Simulation at time: 8.02035 seconds.            
Sun Jan 11 13:42:25 2015        Simulation at time: 8.04009 seconds.            
Sun Jan 11 13:42:25 2015        Simulation at time: 8.05984 seconds.            
Sun Jan 11 13:42:25 2015        Simulation at time: 8.07958 seconds.            
Sun Jan 11 13:42:25 2015        Simulation at time: 8.09933 seconds.            
Sun Jan 11 13:42:25 2015        Simulation at time: 8.11908 seconds.            
Sun Jan 11 13:42:25 2015        Simulation at time: 8.13884 seconds.            
Sun Jan 11 13:42:25 2015        Simulation at time: 8.1586 seconds.             
Sun Jan 11 13:42:25 2015        Simulation at time: 8.17836 seconds.            
Sun Jan 11 13:42:25 2015        Simulation at time: 8.19813 seconds.            
Sun Jan 11 13:42:26 2015        Simulation at time: 8.2179 seconds.             
Sun Jan 11 13:42:26 2015        Simulation at time: 8.23767 seconds.            
Sun Jan 11 13:42:26 2015        Simulation at time: 8.25745 seconds.            
Sun Jan 11 13:42:26 2015        Writing output file at time: 8.25745 seconds    
Sun Jan 11 13:42:31 2015        Simulation at time: 8.27723 seconds.            
Sun Jan 11 13:42:31 2015        Simulation at time: 8.29701 seconds.            
Sun Jan 11 13:42:31 2015        Simulation at time: 8.3168 seconds.             
Sun Jan 11 13:42:32 2015        Simulation at time: 8.33659 seconds.            
Sun Jan 11 13:42:32 2015        Simulation at time: 8.35639 seconds.            
Sun Jan 11 13:42:32 2015        Simulation at time: 8.37619 seconds.            
Sun Jan 11 13:42:32 2015        Simulation at time: 8.396 seconds.              
Sun Jan 11 13:42:32 2015        Simulation at time: 8.41581 seconds.            
Sun Jan 11 13:42:32 2015        Simulation at time: 8.43563 seconds.            
Sun Jan 11 13:42:32 2015        Simulation at time: 8.45545 seconds.            
Sun Jan 11 13:42:32 2015        Simulation at time: 8.47528 seconds.            
Sun Jan 11 13:42:32 2015        Simulation at time: 8.49512 seconds.            
Sun Jan 11 13:42:32 2015        Simulation at time: 8.51495 seconds.            
Sun Jan 11 13:42:32 2015        Simulation at time: 8.5348 seconds.             
Sun Jan 11 13:42:32 2015        Simulation at time: 8.55465 seconds.            
Sun Jan 11 13:42:33 2015        Simulation at time: 8.5745 seconds.             
Sun Jan 11 13:42:33 2015        Simulation at time: 8.59437 seconds.            
Sun Jan 11 13:42:33 2015        Simulation at time: 8.61424 seconds.            
Sun Jan 11 13:42:33 2015        Simulation at time: 8.63411 seconds.            
Sun Jan 11 13:42:33 2015        Simulation at time: 8.654 seconds.              
Sun Jan 11 13:42:33 2015        Simulation at time: 8.67389 seconds.            
Sun Jan 11 13:42:33 2015        Simulation at time: 8.69378 seconds.            
Sun Jan 11 13:42:33 2015        Simulation at time: 8.71369 seconds.            
Sun Jan 11 13:42:33 2015        Simulation at time: 8.7336 seconds.             
Sun Jan 11 13:42:33 2015        Simulation at time: 8.75352 seconds.            
Sun Jan 11 13:42:33 2015        Simulation at time: 8.77345 seconds.            
Sun Jan 11 13:42:33 2015        Simulation at time: 8.79339 seconds.            
Sun Jan 11 13:42:34 2015        Simulation at time: 8.81334 seconds.            
Sun Jan 11 13:42:34 2015        Simulation at time: 8.83329 seconds.            
Sun Jan 11 13:42:34 2015        Simulation at time: 8.85326 seconds.            
Sun Jan 11 13:42:34 2015        Simulation at time: 8.87323 seconds.            
Sun Jan 11 13:42:34 2015        Simulation at time: 8.89322 seconds.            
Sun Jan 11 13:42:34 2015        Simulation at time: 8.91321 seconds.            
Sun Jan 11 13:42:34 2015        Simulation at time: 8.93322 seconds.            
Sun Jan 11 13:42:34 2015        Simulation at time: 8.95324 seconds.            
Sun Jan 11 13:42:34 2015        Simulation at time: 8.97327 seconds.            
Sun Jan 11 13:42:34 2015        Simulation at time: 8.99331 seconds.            
Sun Jan 11 13:42:34 2015        Simulation at time: 9.01336 seconds.            
Sun Jan 11 13:42:34 2015        Writing output file at time: 9.01336 seconds    
Sun Jan 11 13:42:40 2015        Simulation at time: 9.03343 seconds.            
Sun Jan 11 13:42:40 2015        Simulation at time: 9.05351 seconds.            
Sun Jan 11 13:42:40 2015        Simulation at time: 9.0736 seconds.             
Sun Jan 11 13:42:40 2015        Simulation at time: 9.09371 seconds.            
Sun Jan 11 13:42:41 2015        Simulation at time: 9.11383 seconds.            
Sun Jan 11 13:42:41 2015        Simulation at time: 9.13397 seconds.            
Sun Jan 11 13:42:41 2015        Simulation at time: 9.15413 seconds.            
Sun Jan 11 13:42:41 2015        Simulation at time: 9.1743 seconds.             
Sun Jan 11 13:42:41 2015        Simulation at time: 9.19449 seconds.            
Sun Jan 11 13:42:41 2015        Simulation at time: 9.21469 seconds.            
Sun Jan 11 13:42:41 2015        Simulation at time: 9.23492 seconds.            
Sun Jan 11 13:42:41 2015        Simulation at time: 9.25516 seconds.            
Sun Jan 11 13:42:41 2015        Simulation at time: 9.27543 seconds.            
Sun Jan 11 13:42:41 2015        Simulation at time: 9.29571 seconds.            
Sun Jan 11 13:42:41 2015        Simulation at time: 9.31602 seconds.            
Sun Jan 11 13:42:41 2015        Simulation at time: 9.33635 seconds.            
Sun Jan 11 13:42:42 2015        Simulation at time: 9.3567 seconds.             
Sun Jan 11 13:42:42 2015        Simulation at time: 9.37708 seconds.            
Sun Jan 11 13:42:42 2015        Simulation at time: 9.39748 seconds.            
Sun Jan 11 13:42:42 2015        Simulation at time: 9.41791 seconds.            
Sun Jan 11 13:42:42 2015        Simulation at time: 9.43836 seconds.            
Sun Jan 11 13:42:42 2015        Simulation at time: 9.45884 seconds.            
Sun Jan 11 13:42:42 2015        Simulation at time: 9.47935 seconds.            
Sun Jan 11 13:42:42 2015        Simulation at time: 9.49989 seconds.            
Sun Jan 11 13:42:42 2015        Simulation at time: 9.52046 seconds.            
Sun Jan 11 13:42:42 2015        Simulation at time: 9.54106 seconds.            
Sun Jan 11 13:42:43 2015        Simulation at time: 9.5617 seconds.             
Sun Jan 11 13:42:43 2015        Simulation at time: 9.58236 seconds.            
Sun Jan 11 13:42:43 2015        Simulation at time: 9.60306 seconds.            
Sun Jan 11 13:42:43 2015        Simulation at time: 9.6238 seconds.             
Sun Jan 11 13:42:43 2015        Simulation at time: 9.64457 seconds.            
Sun Jan 11 13:42:43 2015        Simulation at time: 9.66538 seconds.            
Sun Jan 11 13:42:43 2015        Simulation at time: 9.68623 seconds.            
Sun Jan 11 13:42:43 2015        Simulation at time: 9.70711 seconds.            
Sun Jan 11 13:42:43 2015        Simulation at time: 9.72804 seconds.            
Sun Jan 11 13:42:43 2015        Simulation at time: 9.749 seconds.              
Sun Jan 11 13:42:43 2015        Simulation at time: 9.77001 seconds.            
Sun Jan 11 13:42:43 2015        Writing output file at time: 9.77001 seconds    
Sun Jan 11 13:42:50 2015        Simulation at time: 9.79106 seconds.            
Sun Jan 11 13:42:50 2015        Simulation at time: 9.81215 seconds.            
Sun Jan 11 13:42:50 2015        Simulation at time: 9.83326 seconds.            
Sun Jan 11 13:42:50 2015        Simulation at time: 9.85439 seconds.            
Sun Jan 11 13:42:50 2015        Simulation at time: 9.87553 seconds.            
Sun Jan 11 13:42:50 2015        Simulation at time: 9.89668 seconds.            
Sun Jan 11 13:42:50 2015        Simulation at time: 9.91785 seconds.            
Sun Jan 11 13:42:50 2015        Simulation at time: 9.93903 seconds.            
Sun Jan 11 13:42:50 2015        Simulation at time: 9.96022 seconds.            
Sun Jan 11 13:42:50 2015        Simulation at time: 9.98142 seconds.            
Sun Jan 11 13:42:50 2015        Simulation at time: 10.0026 seconds.            
Sun Jan 11 13:42:50 2015        Simulation at time: 10.0239 seconds.            
Sun Jan 11 13:42:51 2015        Simulation at time: 10.0451 seconds.            
Sun Jan 11 13:42:51 2015        Simulation at time: 10.0664 seconds.            
Sun Jan 11 13:42:51 2015        Simulation at time: 10.0876 seconds.            
Sun Jan 11 13:42:51 2015        Simulation at time: 10.1089 seconds.            
Sun Jan 11 13:42:51 2015        Simulation at time: 10.1302 seconds.            
Sun Jan 11 13:42:51 2015        Simulation at time: 10.1515 seconds.            
Sun Jan 11 13:42:51 2015        Simulation at time: 10.1728 seconds.            
Sun Jan 11 13:42:51 2015        Simulation at time: 10.1941 seconds.            
Sun Jan 11 13:42:51 2015        Simulation at time: 10.2154 seconds.            
Sun Jan 11 13:42:51 2015        Simulation at time: 10.2367 seconds.            
Sun Jan 11 13:42:51 2015        Simulation at time: 10.258 seconds.             
Sun Jan 11 13:42:52 2015        Simulation at time: 10.2794 seconds.            
Sun Jan 11 13:42:52 2015        Simulation at time: 10.3007 seconds.            
Sun Jan 11 13:42:52 2015        Simulation at time: 10.322 seconds.             
Sun Jan 11 13:42:52 2015        Simulation at time: 10.3434 seconds.            
Sun Jan 11 13:42:52 2015        Simulation at time: 10.3647 seconds.            
Sun Jan 11 13:42:52 2015        Simulation at time: 10.3861 seconds.            
Sun Jan 11 13:42:52 2015        Simulation at time: 10.4074 seconds.            
Sun Jan 11 13:42:52 2015        Simulation at time: 10.4288 seconds.            
Sun Jan 11 13:42:52 2015        Simulation at time: 10.4501 seconds.            
Sun Jan 11 13:42:52 2015        Simulation at time: 10.4715 seconds.            
Sun Jan 11 13:42:52 2015        Simulation at time: 10.4929 seconds.            
Sun Jan 11 13:42:52 2015        Simulation at time: 10.5142 seconds.            
Sun Jan 11 13:42:52 2015        Writing output file at time: 10.5142 seconds    
Sun Jan 11 13:42:58 2015        Simulation at time: 10.5356 seconds.            
Sun Jan 11 13:42:58 2015        Simulation at time: 10.557 seconds.             
Sun Jan 11 13:42:58 2015        Simulation at time: 10.5783 seconds.            
Sun Jan 11 13:42:58 2015        Simulation at time: 10.5997 seconds.            
Sun Jan 11 13:42:59 2015        Simulation at time: 10.6211 seconds.            
Sun Jan 11 13:42:59 2015        Simulation at time: 10.6425 seconds.            
Sun Jan 11 13:42:59 2015        Simulation at time: 10.6639 seconds.            
Sun Jan 11 13:42:59 2015        Simulation at time: 10.6853 seconds.            
Sun Jan 11 13:42:59 2015        Simulation at time: 10.7067 seconds.            
Sun Jan 11 13:42:59 2015        Simulation at time: 10.7281 seconds.            
Sun Jan 11 13:42:59 2015        Simulation at time: 10.7495 seconds.            
Sun Jan 11 13:42:59 2015        Simulation at time: 10.7709 seconds.            
Sun Jan 11 13:42:59 2015        Simulation at time: 10.7923 seconds.            
Sun Jan 11 13:42:59 2015        Simulation at time: 10.8137 seconds.            
Sun Jan 11 13:42:59 2015        Simulation at time: 10.8351 seconds.            
Sun Jan 11 13:42:59 2015        Simulation at time: 10.8566 seconds.            
Sun Jan 11 13:43:00 2015        Simulation at time: 10.878 seconds.             
Sun Jan 11 13:43:00 2015        Simulation at time: 10.8994 seconds.            
Sun Jan 11 13:43:00 2015        Simulation at time: 10.9209 seconds.            
Sun Jan 11 13:43:00 2015        Simulation at time: 10.9423 seconds.            
Sun Jan 11 13:43:00 2015        Simulation at time: 10.9637 seconds.            
Sun Jan 11 13:43:00 2015        Simulation at time: 10.9852 seconds.            
Sun Jan 11 13:43:00 2015        Simulation at time: 11.0066 seconds.            
Sun Jan 11 13:43:00 2015        Simulation at time: 11.0281 seconds.            
Sun Jan 11 13:43:00 2015        Simulation at time: 11.0495 seconds.            
Sun Jan 11 13:43:00 2015        Simulation at time: 11.071 seconds.             
Sun Jan 11 13:43:00 2015        Simulation at time: 11.0924 seconds.            
Sun Jan 11 13:43:01 2015        Simulation at time: 11.1139 seconds.            
Sun Jan 11 13:43:01 2015        Simulation at time: 11.1353 seconds.            
Sun Jan 11 13:43:01 2015        Simulation at time: 11.1568 seconds.            
Sun Jan 11 13:43:01 2015        Simulation at time: 11.1783 seconds.            
Sun Jan 11 13:43:01 2015        Simulation at time: 11.1998 seconds.            
Sun Jan 11 13:43:01 2015        Simulation at time: 11.2212 seconds.            
Sun Jan 11 13:43:01 2015        Simulation at time: 11.2427 seconds.            
Sun Jan 11 13:43:01 2015        Simulation at time: 11.2642 seconds.            
Sun Jan 11 13:43:01 2015        Writing output file at time: 11.2642 seconds    
Sun Jan 11 13:43:07 2015        Simulation at time: 11.2857 seconds.            
Sun Jan 11 13:43:07 2015        Simulation at time: 11.3072 seconds.            
Sun Jan 11 13:43:07 2015        Simulation at time: 11.3287 seconds.            
Sun Jan 11 13:43:07 2015        Simulation at time: 11.3502 seconds.            
Sun Jan 11 13:43:07 2015        Simulation at time: 11.3717 seconds.            
Sun Jan 11 13:43:07 2015        Simulation at time: 11.3932 seconds.            
Sun Jan 11 13:43:07 2015        Simulation at time: 11.4147 seconds.            
Sun Jan 11 13:43:07 2015        Simulation at time: 11.4362 seconds.            
Sun Jan 11 13:43:07 2015        Simulation at time: 11.4577 seconds.            
Sun Jan 11 13:43:08 2015        Simulation at time: 11.4792 seconds.            
Sun Jan 11 13:43:08 2015        Simulation at time: 11.5007 seconds.            
Sun Jan 11 13:43:08 2015        Simulation at time: 11.5222 seconds.            
Sun Jan 11 13:43:08 2015        Simulation at time: 11.5438 seconds.            
Sun Jan 11 13:43:08 2015        Simulation at time: 11.5653 seconds.            
Sun Jan 11 13:43:08 2015        Simulation at time: 11.5868 seconds.            
Sun Jan 11 13:43:08 2015        Simulation at time: 11.6084 seconds.            
Sun Jan 11 13:43:08 2015        Simulation at time: 11.6299 seconds.            
Sun Jan 11 13:43:08 2015        Simulation at time: 11.6514 seconds.            
Sun Jan 11 13:43:08 2015        Simulation at time: 11.673 seconds.             
Sun Jan 11 13:43:08 2015        Simulation at time: 11.6945 seconds.            
Sun Jan 11 13:43:08 2015        Simulation at time: 11.7161 seconds.            
Sun Jan 11 13:43:09 2015        Simulation at time: 11.7376 seconds.            
Sun Jan 11 13:43:09 2015        Simulation at time: 11.7592 seconds.            
Sun Jan 11 13:43:09 2015        Simulation at time: 11.7807 seconds.            
Sun Jan 11 13:43:09 2015        Simulation at time: 11.8023 seconds.            
Sun Jan 11 13:43:09 2015        Simulation at time: 11.8238 seconds.            
Sun Jan 11 13:43:09 2015        Simulation at time: 11.8454 seconds.            
Sun Jan 11 13:43:09 2015        Simulation at time: 11.867 seconds.             
Sun Jan 11 13:43:09 2015        Simulation at time: 11.8885 seconds.            
Sun Jan 11 13:43:09 2015        Simulation at time: 11.9101 seconds.            
Sun Jan 11 13:43:09 2015        Simulation at time: 11.9317 seconds.            
Sun Jan 11 13:43:09 2015        Simulation at time: 11.9532 seconds.            
Sun Jan 11 13:43:10 2015        Simulation at time: 11.9748 seconds.            
Sun Jan 11 13:43:10 2015        Simulation at time: 11.9964 seconds.            
Sun Jan 11 13:43:10 2015        Simulation at time: 12.018 seconds.             
Sun Jan 11 13:43:10 2015        Writing output file at time: 12.018 seconds     
Sun Jan 11 13:43:16 2015        Simulation at time: 12.0396 seconds.            
Sun Jan 11 13:43:16 2015        Simulation at time: 12.0612 seconds.            
Sun Jan 11 13:43:16 2015        Simulation at time: 12.0827 seconds.            
Sun Jan 11 13:43:16 2015        Simulation at time: 12.1043 seconds.            
Sun Jan 11 13:43:16 2015        Simulation at time: 12.1259 seconds.            
Sun Jan 11 13:43:16 2015        Simulation at time: 12.1475 seconds.            
Sun Jan 11 13:43:16 2015        Simulation at time: 12.1691 seconds.            
Sun Jan 11 13:43:16 2015        Simulation at time: 12.1907 seconds.            
Sun Jan 11 13:43:16 2015        Simulation at time: 12.2124 seconds.            
Sun Jan 11 13:43:16 2015        Simulation at time: 12.234 seconds.             
Sun Jan 11 13:43:17 2015        Simulation at time: 12.2556 seconds.            
Sun Jan 11 13:43:17 2015        Simulation at time: 12.2772 seconds.            
Sun Jan 11 13:43:17 2015        Simulation at time: 12.2988 seconds.            
Sun Jan 11 13:43:17 2015        Simulation at time: 12.3204 seconds.            
Sun Jan 11 13:43:17 2015        Simulation at time: 12.342 seconds.             
Sun Jan 11 13:43:17 2015        Simulation at time: 12.3637 seconds.            
Sun Jan 11 13:43:17 2015        Simulation at time: 12.3853 seconds.            
Sun Jan 11 13:43:17 2015        Simulation at time: 12.4069 seconds.            
Sun Jan 11 13:43:17 2015        Simulation at time: 12.4286 seconds.            
Sun Jan 11 13:43:17 2015        Simulation at time: 12.4502 seconds.            
Sun Jan 11 13:43:17 2015        Simulation at time: 12.4718 seconds.            
Sun Jan 11 13:43:17 2015        Simulation at time: 12.4935 seconds.            
Sun Jan 11 13:43:18 2015        Simulation at time: 12.5151 seconds.            
Sun Jan 11 13:43:18 2015        Simulation at time: 12.5368 seconds.            
Sun Jan 11 13:43:18 2015        Simulation at time: 12.5584 seconds.            
Sun Jan 11 13:43:18 2015        Simulation at time: 12.5801 seconds.            
Sun Jan 11 13:43:18 2015        Simulation at time: 12.6017 seconds.            
Sun Jan 11 13:43:18 2015        Simulation at time: 12.6234 seconds.            
Sun Jan 11 13:43:18 2015        Simulation at time: 12.645 seconds.             
Sun Jan 11 13:43:18 2015        Simulation at time: 12.6667 seconds.            
Sun Jan 11 13:43:18 2015        Simulation at time: 12.6883 seconds.            
Sun Jan 11 13:43:18 2015        Simulation at time: 12.71 seconds.              
Sun Jan 11 13:43:18 2015        Simulation at time: 12.7317 seconds.            
Sun Jan 11 13:43:19 2015        Simulation at time: 12.7533 seconds.            
Sun Jan 11 13:43:19 2015        Writing output file at time: 12.7533 seconds    
Sun Jan 11 13:43:24 2015        Simulation at time: 12.775 seconds.             
Sun Jan 11 13:43:24 2015        Simulation at time: 12.7967 seconds.            
Sun Jan 11 13:43:24 2015        Simulation at time: 12.8184 seconds.            
Sun Jan 11 13:43:24 2015        Simulation at time: 12.8401 seconds.            
Sun Jan 11 13:43:24 2015        Simulation at time: 12.8617 seconds.            
Sun Jan 11 13:43:25 2015        Simulation at time: 12.8834 seconds.            
Sun Jan 11 13:43:25 2015        Simulation at time: 12.9051 seconds.            
Sun Jan 11 13:43:25 2015        Simulation at time: 12.9268 seconds.            
Sun Jan 11 13:43:25 2015        Simulation at time: 12.9485 seconds.            
Sun Jan 11 13:43:25 2015        Simulation at time: 12.9702 seconds.            
Sun Jan 11 13:43:25 2015        Simulation at time: 12.9919 seconds.            
Sun Jan 11 13:43:25 2015        Simulation at time: 13.0136 seconds.            
Sun Jan 11 13:43:25 2015        Simulation at time: 13.0353 seconds.            
Sun Jan 11 13:43:25 2015        Simulation at time: 13.057 seconds.             
Sun Jan 11 13:43:25 2015        Simulation at time: 13.0787 seconds.            
Sun Jan 11 13:43:25 2015        Simulation at time: 13.1004 seconds.            
Sun Jan 11 13:43:26 2015        Simulation at time: 13.1221 seconds.            
Sun Jan 11 13:43:26 2015        Simulation at time: 13.1438 seconds.            
Sun Jan 11 13:43:26 2015        Simulation at time: 13.1655 seconds.            
Sun Jan 11 13:43:26 2015        Simulation at time: 13.1872 seconds.            
Sun Jan 11 13:43:26 2015        Simulation at time: 13.2089 seconds.            
Sun Jan 11 13:43:26 2015        Simulation at time: 13.2307 seconds.            
Sun Jan 11 13:43:26 2015        Simulation at time: 13.2524 seconds.            
Sun Jan 11 13:43:26 2015        Simulation at time: 13.2741 seconds.            
Sun Jan 11 13:43:26 2015        Simulation at time: 13.2958 seconds.            
Sun Jan 11 13:43:26 2015        Simulation at time: 13.3176 seconds.            
Sun Jan 11 13:43:26 2015        Simulation at time: 13.3393 seconds.            
Sun Jan 11 13:43:26 2015        Simulation at time: 13.361 seconds.             
Sun Jan 11 13:43:27 2015        Simulation at time: 13.3828 seconds.            
Sun Jan 11 13:43:27 2015        Simulation at time: 13.4045 seconds.            
Sun Jan 11 13:43:27 2015        Simulation at time: 13.4262 seconds.            
Sun Jan 11 13:43:27 2015        Simulation at time: 13.448 seconds.             
Sun Jan 11 13:43:27 2015        Simulation at time: 13.4697 seconds.            
Sun Jan 11 13:43:27 2015        Simulation at time: 13.4915 seconds.            
Sun Jan 11 13:43:27 2015        Simulation at time: 13.5132 seconds.            
Sun Jan 11 13:43:27 2015        Writing output file at time: 13.5132 seconds    
Sun Jan 11 13:43:33 2015        Simulation at time: 13.535 seconds.             
Sun Jan 11 13:43:33 2015        Simulation at time: 13.5567 seconds.            
Sun Jan 11 13:43:33 2015        Simulation at time: 13.5785 seconds.            
Sun Jan 11 13:43:33 2015        Simulation at time: 13.6002 seconds.            
Sun Jan 11 13:43:33 2015        Simulation at time: 13.622 seconds.             
Sun Jan 11 13:43:33 2015        Simulation at time: 13.6437 seconds.            
Sun Jan 11 13:43:33 2015        Simulation at time: 13.6655 seconds.            
Sun Jan 11 13:43:33 2015        Simulation at time: 13.6873 seconds.            
Sun Jan 11 13:43:33 2015        Simulation at time: 13.709 seconds.             
Sun Jan 11 13:43:33 2015        Simulation at time: 13.7308 seconds.            
Sun Jan 11 13:43:34 2015        Simulation at time: 13.7526 seconds.            
Sun Jan 11 13:43:34 2015        Simulation at time: 13.7743 seconds.            
Sun Jan 11 13:43:34 2015        Simulation at time: 13.7961 seconds.            
Sun Jan 11 13:43:34 2015        Simulation at time: 13.8179 seconds.            
Sun Jan 11 13:43:34 2015        Simulation at time: 13.8396 seconds.            
Sun Jan 11 13:43:34 2015        Simulation at time: 13.8614 seconds.            
Sun Jan 11 13:43:34 2015        Simulation at time: 13.8832 seconds.            
Sun Jan 11 13:43:34 2015        Simulation at time: 13.905 seconds.             
Sun Jan 11 13:43:34 2015        Simulation at time: 13.9268 seconds.            
Sun Jan 11 13:43:34 2015        Simulation at time: 13.9486 seconds.            
Sun Jan 11 13:43:34 2015        Simulation at time: 13.9704 seconds.            
Sun Jan 11 13:43:35 2015        Simulation at time: 13.9921 seconds.            
Sun Jan 11 13:43:35 2015        Simulation at time: 14.0139 seconds.            
Sun Jan 11 13:43:35 2015        Simulation at time: 14.0357 seconds.            
Sun Jan 11 13:43:35 2015        Simulation at time: 14.0575 seconds.            
Sun Jan 11 13:43:35 2015        Simulation at time: 14.0793 seconds.            
Sun Jan 11 13:43:35 2015        Simulation at time: 14.1011 seconds.            
Sun Jan 11 13:43:35 2015        Simulation at time: 14.1229 seconds.            
Sun Jan 11 13:43:35 2015        Simulation at time: 14.1447 seconds.            
Sun Jan 11 13:43:35 2015        Simulation at time: 14.1665 seconds.            
Sun Jan 11 13:43:35 2015        Simulation at time: 14.1884 seconds.            
Sun Jan 11 13:43:35 2015        Simulation at time: 14.2102 seconds.            
Sun Jan 11 13:43:35 2015        Simulation at time: 14.232 seconds.             
Sun Jan 11 13:43:36 2015        Simulation at time: 14.2538 seconds.            
Sun Jan 11 13:43:36 2015        Writing output file at time: 14.2538 seconds    
Sun Jan 11 13:43:41 2015        Simulation at time: 14.2756 seconds.            
Sun Jan 11 13:43:41 2015        Simulation at time: 14.2974 seconds.            
Sun Jan 11 13:43:41 2015        Simulation at time: 14.3193 seconds.            
Sun Jan 11 13:43:41 2015        Simulation at time: 14.3411 seconds.            
Sun Jan 11 13:43:42 2015        Simulation at time: 14.3629 seconds.            
Sun Jan 11 13:43:42 2015        Simulation at time: 14.3847 seconds.            
Sun Jan 11 13:43:42 2015        Simulation at time: 14.4066 seconds.            
Sun Jan 11 13:43:42 2015        Simulation at time: 14.4284 seconds.            
Sun Jan 11 13:43:42 2015        Simulation at time: 14.4502 seconds.            
Sun Jan 11 13:43:42 2015        Simulation at time: 14.4721 seconds.            
Sun Jan 11 13:43:42 2015        Simulation at time: 14.4939 seconds.            
Sun Jan 11 13:43:42 2015        Simulation at time: 14.5157 seconds.            
Sun Jan 11 13:43:42 2015        Simulation at time: 14.5376 seconds.            
Sun Jan 11 13:43:42 2015        Simulation at time: 14.5594 seconds.            
Sun Jan 11 13:43:42 2015        Simulation at time: 14.5813 seconds.            
Sun Jan 11 13:43:43 2015        Simulation at time: 14.6031 seconds.            
Sun Jan 11 13:43:43 2015        Simulation at time: 14.625 seconds.             
Sun Jan 11 13:43:43 2015        Simulation at time: 14.6468 seconds.            
Sun Jan 11 13:43:43 2015        Simulation at time: 14.6687 seconds.            
Sun Jan 11 13:43:43 2015        Simulation at time: 14.6905 seconds.            
Sun Jan 11 13:43:43 2015        Simulation at time: 14.7124 seconds.            
Sun Jan 11 13:43:43 2015        Simulation at time: 14.7342 seconds.            
Sun Jan 11 13:43:43 2015        Simulation at time: 14.7561 seconds.            
Sun Jan 11 13:43:43 2015        Simulation at time: 14.7779 seconds.            
Sun Jan 11 13:43:43 2015        Simulation at time: 14.7998 seconds.            
Sun Jan 11 13:43:43 2015        Simulation at time: 14.8217 seconds.            
Sun Jan 11 13:43:43 2015        Simulation at time: 14.8435 seconds.            
Sun Jan 11 13:43:44 2015        Simulation at time: 14.8654 seconds.            
Sun Jan 11 13:43:44 2015        Simulation at time: 14.8873 seconds.            
Sun Jan 11 13:43:44 2015        Simulation at time: 14.9092 seconds.            
Sun Jan 11 13:43:44 2015        Simulation at time: 14.931 seconds.             
Sun Jan 11 13:43:44 2015        Simulation at time: 14.9529 seconds.            
Sun Jan 11 13:43:44 2015        Simulation at time: 14.9748 seconds.            
Sun Jan 11 13:43:44 2015        Simulation at time: 14.9967 seconds.            
Sun Jan 11 13:43:44 2015        Simulation at time: 15.0186 seconds.            
Sun Jan 11 13:43:44 2015        Writing output file at time: 15.0186 seconds    
                                                                                
------------------------------------------------------------------
Sun Jan 11 13:43:50 2015	Simulation finished. Printing statistics for each process.
------------------------------------------------------------------
Sun Jan 11 13:43:50 2015	process 0 - CPU time: 127.13 seconds
Sun Jan 11 13:43:50 2015	process 0 - wall clock time: 301 seconds
Sun Jan 11 13:43:50 2015	733 iterations done

*************************************************************
SWE finished successfully.
*************************************************************

real	5m11.899s
user	2m17.493s
sys	1m58.387s

*************************************************************
Welcome to SWE

SWE Copyright (C) 2012-2013
  Technische Universitaet Muenchen
  Department of Informatics
  Chair of Scientific Computing
  http://www5.in.tum.de/SWE

SWE comes with ABSOLUTELY NO WARRANTY.
SWE is free software, and you are welcome to redistribute it
under certain conditions.
Details can be found in the file 'gpl.txt'.
*************************************************************
Sun Jan 11 13:43:51 2015	Writing output file at time: 0 seconds
                                                                                
------------------------------------------------------------------
Sun Jan 11 13:44:00 2015	Everything is set up, starting the simulation.
------------------------------------------------------------------
Sun Jan 11 13:44:00 2015        Simulation at time: 0.0219831 seconds.          
Sun Jan 11 13:44:01 2015        Simulation at time: 0.0432806 seconds.          
Sun Jan 11 13:44:01 2015        Simulation at time: 0.0642069 seconds.          
Sun Jan 11 13:44:01 2015        Simulation at time: 0.0848982 seconds.          
Sun Jan 11 13:44:01 2015        Simulation at time: 0.105438 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.125793 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.146023 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.166186 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.186302 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.206399 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.226492 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.246591 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.266673 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.286752 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.306841 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.326948 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.347074 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.367217 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.387362 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.407508 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.427655 seconds.           
Sun Jan 11 13:44:01 2015        Simulation at time: 0.447803 seconds.           
Sun Jan 11 13:44:02 2015        Simulation at time: 0.467952 seconds.           
Sun Jan 11 13:44:02 2015        Simulation at time: 0.488099 seconds.           
Sun Jan 11 13:44:02 2015        Simulation at time: 0.508247 seconds.           
Sun Jan 11 13:44:02 2015        Simulation at time: 0.528394 seconds.           
Sun Jan 11 13:44:02 2015        Simulation at time: 0.548542 seconds.           
Sun Jan 11 13:44:02 2015        Simulation at time: 0.568689 seconds.           
Sun Jan 11 13:44:02 2015        Simulation at time: 0.588834 seconds.           
Sun Jan 11 13:44:02 2015        Simulation at time: 0.608978 seconds.           
Sun Jan 11 13:44:02 2015        Simulation at time: 0.629122 seconds.           
Sun Jan 11 13:44:02 2015        Simulation at time: 0.649266 seconds.           
Sun Jan 11 13:44:02 2015        Simulation at time: 0.669409 seconds.           
Sun Jan 11 13:44:02 2015        Simulation at time: 0.68955 seconds.            
Sun Jan 11 13:44:02 2015        Simulation at time: 0.70969 seconds.            
Sun Jan 11 13:44:02 2015        Simulation at time: 0.729831 seconds.           
Sun Jan 11 13:44:02 2015        Simulation at time: 0.749971 seconds.           
Sun Jan 11 13:44:02 2015        Simulation at time: 0.770112 seconds.           
Sun Jan 11 13:44:02 2015        Writing output file at time: 0.770112 seconds   
Sun Jan 11 13:44:08 2015        Simulation at time: 0.790251 seconds.           
Sun Jan 11 13:44:08 2015        Simulation at time: 0.810388 seconds.           
Sun Jan 11 13:44:08 2015        Simulation at time: 0.830525 seconds.           
Sun Jan 11 13:44:08 2015        Simulation at time: 0.850662 seconds.           
Sun Jan 11 13:44:08 2015        Simulation at time: 0.870797 seconds.           
Sun Jan 11 13:44:08 2015        Simulation at time: 0.890927 seconds.           
Sun Jan 11 13:44:08 2015        Simulation at time: 0.911055 seconds.           
Sun Jan 11 13:44:08 2015        Simulation at time: 0.931181 seconds.           
Sun Jan 11 13:44:08 2015        Simulation at time: 0.951306 seconds.           
Sun Jan 11 13:44:08 2015        Simulation at time: 0.971428 seconds.           
Sun Jan 11 13:44:08 2015        Simulation at time: 0.991548 seconds.           
Sun Jan 11 13:44:08 2015        Simulation at time: 1.01167 seconds.            
Sun Jan 11 13:44:08 2015        Simulation at time: 1.03178 seconds.            
Sun Jan 11 13:44:08 2015        Simulation at time: 1.0519 seconds.             
Sun Jan 11 13:44:08 2015        Simulation at time: 1.07201 seconds.            
Sun Jan 11 13:44:08 2015        Simulation at time: 1.09212 seconds.            
Sun Jan 11 13:44:08 2015        Simulation at time: 1.11223 seconds.            
Sun Jan 11 13:44:08 2015        Simulation at time: 1.13234 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.15245 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.17256 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.19267 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.21277 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.23288 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.25298 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.27309 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.29319 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.31329 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.33339 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.35349 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.37359 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.39368 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.41378 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.43387 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.45397 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.47406 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.49415 seconds.            
Sun Jan 11 13:44:09 2015        Simulation at time: 1.51424 seconds.            
Sun Jan 11 13:44:09 2015        Writing output file at time: 1.51424 seconds    
Sun Jan 11 13:44:15 2015        Simulation at time: 1.53432 seconds.            
Sun Jan 11 13:44:15 2015        Simulation at time: 1.55441 seconds.            
Sun Jan 11 13:44:15 2015        Simulation at time: 1.5745 seconds.             
Sun Jan 11 13:44:15 2015        Simulation at time: 1.59458 seconds.            
Sun Jan 11 13:44:15 2015        Simulation at time: 1.61466 seconds.            
Sun Jan 11 13:44:15 2015        Simulation at time: 1.63474 seconds.            
Sun Jan 11 13:44:15 2015        Simulation at time: 1.65482 seconds.            
Sun Jan 11 13:44:15 2015        Simulation at time: 1.6749 seconds.             
Sun Jan 11 13:44:15 2015        Simulation at time: 1.69497 seconds.            
Sun Jan 11 13:44:15 2015        Simulation at time: 1.71505 seconds.            
Sun Jan 11 13:44:15 2015        Simulation at time: 1.73512 seconds.            
Sun Jan 11 13:44:15 2015        Simulation at time: 1.75519 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 1.77526 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 1.79533 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 1.8154 seconds.             
Sun Jan 11 13:44:16 2015        Simulation at time: 1.83546 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 1.85553 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 1.87559 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 1.89565 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 1.91571 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 1.93577 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 1.95582 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 1.97588 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 1.99593 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 2.01598 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 2.03603 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 2.05608 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 2.07613 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 2.09617 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 2.11622 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 2.13626 seconds.            
Sun Jan 11 13:44:16 2015        Simulation at time: 2.1563 seconds.             
Sun Jan 11 13:44:16 2015        Simulation at time: 2.17634 seconds.            
Sun Jan 11 13:44:17 2015        Simulation at time: 2.19637 seconds.            
Sun Jan 11 13:44:17 2015        Simulation at time: 2.21641 seconds.            
Sun Jan 11 13:44:17 2015        Simulation at time: 2.23644 seconds.            
Sun Jan 11 13:44:17 2015        Simulation at time: 2.25647 seconds.            
Sun Jan 11 13:44:17 2015        Writing output file at time: 2.25647 seconds    
Sun Jan 11 13:44:22 2015        Simulation at time: 2.2765 seconds.             
Sun Jan 11 13:44:22 2015        Simulation at time: 2.29653 seconds.            
Sun Jan 11 13:44:22 2015        Simulation at time: 2.31656 seconds.            
Sun Jan 11 13:44:22 2015        Simulation at time: 2.33658 seconds.            
Sun Jan 11 13:44:22 2015        Simulation at time: 2.35661 seconds.            
Sun Jan 11 13:44:22 2015        Simulation at time: 2.37663 seconds.            
Sun Jan 11 13:44:22 2015        Simulation at time: 2.39665 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.41667 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.43668 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.4567 seconds.             
Sun Jan 11 13:44:23 2015        Simulation at time: 2.47671 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.49672 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.51673 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.53674 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.55675 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.57675 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.59676 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.61676 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.63676 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.65676 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.67675 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.69675 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.71674 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.73674 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.75673 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.77671 seconds.            
Sun Jan 11 13:44:23 2015        Simulation at time: 2.7967 seconds.             
Sun Jan 11 13:44:23 2015        Simulation at time: 2.81669 seconds.            
Sun Jan 11 13:44:24 2015        Simulation at time: 2.83667 seconds.            
Sun Jan 11 13:44:24 2015        Simulation at time: 2.85665 seconds.            
Sun Jan 11 13:44:24 2015        Simulation at time: 2.87663 seconds.            
Sun Jan 11 13:44:24 2015        Simulation at time: 2.89661 seconds.            
Sun Jan 11 13:44:24 2015        Simulation at time: 2.91659 seconds.            
Sun Jan 11 13:44:24 2015        Simulation at time: 2.93656 seconds.            
Sun Jan 11 13:44:24 2015        Simulation at time: 2.95654 seconds.            
Sun Jan 11 13:44:24 2015        Simulation at time: 2.97651 seconds.            
Sun Jan 11 13:44:24 2015        Simulation at time: 2.99648 seconds.            
Sun Jan 11 13:44:24 2015        Simulation at time: 3.01645 seconds.            
Sun Jan 11 13:44:24 2015        Writing output file at time: 3.01645 seconds    
Sun Jan 11 13:44:30 2015        Simulation at time: 3.03642 seconds.            
Sun Jan 11 13:44:30 2015        Simulation at time: 3.05638 seconds.            
Sun Jan 11 13:44:30 2015        Simulation at time: 3.07634 seconds.            
Sun Jan 11 13:44:30 2015        Simulation at time: 3.09631 seconds.            
Sun Jan 11 13:44:30 2015        Simulation at time: 3.11627 seconds.            
Sun Jan 11 13:44:30 2015        Simulation at time: 3.13623 seconds.            
Sun Jan 11 13:44:30 2015        Simulation at time: 3.15618 seconds.            
Sun Jan 11 13:44:30 2015        Simulation at time: 3.17614 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.19609 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.21604 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.236 seconds.              
Sun Jan 11 13:44:31 2015        Simulation at time: 3.25594 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.27589 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.29584 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.31578 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.33572 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.35566 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.3756 seconds.             
Sun Jan 11 13:44:31 2015        Simulation at time: 3.39554 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.41547 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.43541 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.45534 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.47527 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.49519 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.51512 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.53505 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.55497 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.57489 seconds.            
Sun Jan 11 13:44:31 2015        Simulation at time: 3.59481 seconds.            
Sun Jan 11 13:44:32 2015        Simulation at time: 3.61473 seconds.            
Sun Jan 11 13:44:32 2015        Simulation at time: 3.63464 seconds.            
Sun Jan 11 13:44:32 2015        Simulation at time: 3.65456 seconds.            
Sun Jan 11 13:44:32 2015        Simulation at time: 3.67447 seconds.            
Sun Jan 11 13:44:32 2015        Simulation at time: 3.69438 seconds.            
Sun Jan 11 13:44:32 2015        Simulation at time: 3.71429 seconds.            
Sun Jan 11 13:44:32 2015        Simulation at time: 3.73419 seconds.            
Sun Jan 11 13:44:32 2015        Simulation at time: 3.7541 seconds.             
Sun Jan 11 13:44:32 2015        Writing output file at time: 3.7541 seconds     
Sun Jan 11 13:44:38 2015        Simulation at time: 3.774 seconds.              
Sun Jan 11 13:44:38 2015        Simulation at time: 3.7939 seconds.             
Sun Jan 11 13:44:38 2015        Simulation at time: 3.8138 seconds.             
Sun Jan 11 13:44:38 2015        Simulation at time: 3.8337 seconds.             
Sun Jan 11 13:44:38 2015        Simulation at time: 3.85359 seconds.            
Sun Jan 11 13:44:38 2015        Simulation at time: 3.87349 seconds.            
Sun Jan 11 13:44:38 2015        Simulation at time: 3.89338 seconds.            
Sun Jan 11 13:44:38 2015        Simulation at time: 3.91327 seconds.            
Sun Jan 11 13:44:38 2015        Simulation at time: 3.93316 seconds.            
Sun Jan 11 13:44:38 2015        Simulation at time: 3.95304 seconds.            
Sun Jan 11 13:44:38 2015        Simulation at time: 3.97293 seconds.            
Sun Jan 11 13:44:38 2015        Simulation at time: 3.99281 seconds.            
Sun Jan 11 13:44:38 2015        Simulation at time: 4.01269 seconds.            
Sun Jan 11 13:44:38 2015        Simulation at time: 4.03257 seconds.            
Sun Jan 11 13:44:38 2015        Simulation at time: 4.05245 seconds.            
Sun Jan 11 13:44:38 2015        Simulation at time: 4.07232 seconds.            
Sun Jan 11 13:44:38 2015        Simulation at time: 4.0922 seconds.             
Sun Jan 11 13:44:38 2015        Simulation at time: 4.11207 seconds.            
Sun Jan 11 13:44:38 2015        Simulation at time: 4.13194 seconds.            
Sun Jan 11 13:44:38 2015        Simulation at time: 4.1518 seconds.             
Sun Jan 11 13:44:38 2015        Simulation at time: 4.17167 seconds.            
Sun Jan 11 13:44:38 2015        Simulation at time: 4.19153 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.21139 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.23125 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.25111 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.27097 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.29082 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.31067 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.33053 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.35037 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.37022 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.39006 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.40991 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.42975 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.44959 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.46943 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.48926 seconds.            
Sun Jan 11 13:44:39 2015        Simulation at time: 4.50909 seconds.            
Sun Jan 11 13:44:39 2015        Writing output file at time: 4.50909 seconds    
Sun Jan 11 13:44:45 2015        Simulation at time: 4.52893 seconds.            
Sun Jan 11 13:44:45 2015        Simulation at time: 4.54876 seconds.            
Sun Jan 11 13:44:45 2015        Simulation at time: 4.56858 seconds.            
Sun Jan 11 13:44:45 2015        Simulation at time: 4.58841 seconds.            
Sun Jan 11 13:44:45 2015        Simulation at time: 4.60823 seconds.            
Sun Jan 11 13:44:45 2015        Simulation at time: 4.62806 seconds.            
Sun Jan 11 13:44:45 2015        Simulation at time: 4.64788 seconds.            
Sun Jan 11 13:44:45 2015        Simulation at time: 4.6677 seconds.             
Sun Jan 11 13:44:45 2015        Simulation at time: 4.68751 seconds.            
Sun Jan 11 13:44:45 2015        Simulation at time: 4.70733 seconds.            
Sun Jan 11 13:44:45 2015        Simulation at time: 4.72714 seconds.            
Sun Jan 11 13:44:45 2015        Simulation at time: 4.74695 seconds.            
Sun Jan 11 13:44:45 2015        Simulation at time: 4.76676 seconds.            
Sun Jan 11 13:44:45 2015        Simulation at time: 4.78657 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 4.80638 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 4.82618 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 4.84598 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 4.86578 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 4.88558 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 4.90538 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 4.92517 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 4.94497 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 4.96476 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 4.98455 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 5.00434 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 5.02412 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 5.04391 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 5.06369 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 5.08348 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 5.10325 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 5.12303 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 5.14281 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 5.16259 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 5.18236 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 5.20213 seconds.            
Sun Jan 11 13:44:46 2015        Simulation at time: 5.2219 seconds.             
Sun Jan 11 13:44:47 2015        Simulation at time: 5.24167 seconds.            
Sun Jan 11 13:44:47 2015        Simulation at time: 5.26144 seconds.            
Sun Jan 11 13:44:47 2015        Writing output file at time: 5.26144 seconds    
Sun Jan 11 13:44:52 2015        Simulation at time: 5.2812 seconds.             
Sun Jan 11 13:44:52 2015        Simulation at time: 5.30097 seconds.            
Sun Jan 11 13:44:52 2015        Simulation at time: 5.32073 seconds.            
Sun Jan 11 13:44:52 2015        Simulation at time: 5.34049 seconds.            
Sun Jan 11 13:44:52 2015        Simulation at time: 5.36025 seconds.            
Sun Jan 11 13:44:52 2015        Simulation at time: 5.38001 seconds.            
Sun Jan 11 13:44:52 2015        Simulation at time: 5.39976 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.41952 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.43927 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.45902 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.47877 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.49852 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.51827 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.53801 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.55775 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.5775 seconds.             
Sun Jan 11 13:44:53 2015        Simulation at time: 5.59724 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.61698 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.63672 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.65645 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.67619 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.69592 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.71566 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.73539 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.75512 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.77485 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.79458 seconds.            
Sun Jan 11 13:44:53 2015        Simulation at time: 5.8143 seconds.             
Sun Jan 11 13:44:53 2015        Simulation at time: 5.83403 seconds.            
Sun Jan 11 13:44:54 2015        Simulation at time: 5.85375 seconds.            
Sun Jan 11 13:44:54 2015        Simulation at time: 5.87347 seconds.            
Sun Jan 11 13:44:54 2015        Simulation at time: 5.89319 seconds.            
Sun Jan 11 13:44:54 2015        Simulation at time: 5.91291 seconds.            
Sun Jan 11 13:44:54 2015        Simulation at time: 5.93263 seconds.            
Sun Jan 11 13:44:54 2015        Simulation at time: 5.95235 seconds.            
Sun Jan 11 13:44:54 2015        Simulation at time: 5.97207 seconds.            
Sun Jan 11 13:44:54 2015        Simulation at time: 5.99178 seconds.            
Sun Jan 11 13:44:54 2015        Simulation at time: 6.01149 seconds.            
Sun Jan 11 13:44:54 2015        Writing output file at time: 6.01149 seconds    
Sun Jan 11 13:45:00 2015        Simulation at time: 6.03121 seconds.            
Sun Jan 11 13:45:00 2015        Simulation at time: 6.05092 seconds.            
Sun Jan 11 13:45:00 2015        Simulation at time: 6.07063 seconds.            
Sun Jan 11 13:45:00 2015        Simulation at time: 6.09034 seconds.            
Sun Jan 11 13:45:00 2015        Simulation at time: 6.11005 seconds.            
Sun Jan 11 13:45:00 2015        Simulation at time: 6.12975 seconds.            
Sun Jan 11 13:45:00 2015        Simulation at time: 6.14946 seconds.            
Sun Jan 11 13:45:00 2015        Simulation at time: 6.16916 seconds.            
Sun Jan 11 13:45:00 2015        Simulation at time: 6.18887 seconds.            
Sun Jan 11 13:45:00 2015        Simulation at time: 6.20857 seconds.            
Sun Jan 11 13:45:00 2015        Simulation at time: 6.22827 seconds.            
Sun Jan 11 13:45:00 2015        Simulation at time: 6.24797 seconds.            
Sun Jan 11 13:45:00 2015        Simulation at time: 6.26767 seconds.            
Sun Jan 11 13:45:00 2015        Simulation at time: 6.28737 seconds.            
Sun Jan 11 13:45:00 2015        Simulation at time: 6.30707 seconds.            
Sun Jan 11 13:45:00 2015        Simulation at time: 6.32677 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.34646 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.36616 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.38585 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.40555 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.42524 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.44493 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.46462 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.48431 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.504 seconds.              
Sun Jan 11 13:45:01 2015        Simulation at time: 6.52369 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.54338 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.56307 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.58276 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.60244 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.62213 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.64181 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.6615 seconds.             
Sun Jan 11 13:45:01 2015        Simulation at time: 6.68118 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.70087 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.72055 seconds.            
Sun Jan 11 13:45:01 2015        Simulation at time: 6.74023 seconds.            
Sun Jan 11 13:45:02 2015        Simulation at time: 6.75991 seconds.            
Sun Jan 11 13:45:02 2015        Writing output file at time: 6.75991 seconds    
Sun Jan 11 13:45:07 2015        Simulation at time: 6.7796 seconds.             
Sun Jan 11 13:45:07 2015        Simulation at time: 6.79928 seconds.            
Sun Jan 11 13:45:07 2015        Simulation at time: 6.81896 seconds.            
Sun Jan 11 13:45:07 2015        Simulation at time: 6.83864 seconds.            
Sun Jan 11 13:45:07 2015        Simulation at time: 6.85832 seconds.            
Sun Jan 11 13:45:07 2015        Simulation at time: 6.878 seconds.              
Sun Jan 11 13:45:07 2015        Simulation at time: 6.89768 seconds.            
Sun Jan 11 13:45:07 2015        Simulation at time: 6.91736 seconds.            
Sun Jan 11 13:45:07 2015        Simulation at time: 6.93704 seconds.            
Sun Jan 11 13:45:07 2015        Simulation at time: 6.95672 seconds.            
Sun Jan 11 13:45:07 2015        Simulation at time: 6.9764 seconds.             
Sun Jan 11 13:45:07 2015        Simulation at time: 6.99608 seconds.            
Sun Jan 11 13:45:07 2015        Simulation at time: 7.01576 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.03544 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.05512 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.0748 seconds.             
Sun Jan 11 13:45:08 2015        Simulation at time: 7.09448 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.11416 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.13384 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.15352 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.1732 seconds.             
Sun Jan 11 13:45:08 2015        Simulation at time: 7.19288 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.21256 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.23225 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.25193 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.27161 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.29129 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.31098 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.33066 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.35035 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.37003 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.38972 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.4094 seconds.             
Sun Jan 11 13:45:08 2015        Simulation at time: 7.42909 seconds.            
Sun Jan 11 13:45:08 2015        Simulation at time: 7.44878 seconds.            
Sun Jan 11 13:45:09 2015        Simulation at time: 7.46847 seconds.            
Sun Jan 11 13:45:09 2015        Simulation at time: 7.48816 seconds.            
Sun Jan 11 13:45:09 2015        Simulation at time: 7.50785 seconds.            
Sun Jan 11 13:45:09 2015        Writing output file at time: 7.50785 seconds    
Sun Jan 11 13:45:14 2015        Simulation at time: 7.52754 seconds.            
Sun Jan 11 13:45:14 2015        Simulation at time: 7.54724 seconds.            
Sun Jan 11 13:45:14 2015        Simulation at time: 7.56693 seconds.            
Sun Jan 11 13:45:14 2015        Simulation at time: 7.58663 seconds.            
Sun Jan 11 13:45:14 2015        Simulation at time: 7.60632 seconds.            
Sun Jan 11 13:45:14 2015        Simulation at time: 7.62602 seconds.            
Sun Jan 11 13:45:14 2015        Simulation at time: 7.64572 seconds.            
Sun Jan 11 13:45:14 2015        Simulation at time: 7.66542 seconds.            
Sun Jan 11 13:45:14 2015        Simulation at time: 7.68512 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 7.70483 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 7.72453 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 7.74424 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 7.76395 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 7.78366 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 7.80337 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 7.82309 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 7.8428 seconds.             
Sun Jan 11 13:45:15 2015        Simulation at time: 7.86252 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 7.88224 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 7.90197 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 7.92169 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 7.94142 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 7.96115 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 7.98088 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 8.00062 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 8.02035 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 8.04009 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 8.05984 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 8.07958 seconds.            
Sun Jan 11 13:45:15 2015        Simulation at time: 8.09933 seconds.            
Sun Jan 11 13:45:16 2015        Simulation at time: 8.11908 seconds.            
Sun Jan 11 13:45:16 2015        Simulation at time: 8.13884 seconds.            
Sun Jan 11 13:45:16 2015        Simulation at time: 8.1586 seconds.             
Sun Jan 11 13:45:16 2015        Simulation at time: 8.17836 seconds.            
Sun Jan 11 13:45:16 2015        Simulation at time: 8.19813 seconds.            
Sun Jan 11 13:45:16 2015        Simulation at time: 8.2179 seconds.             
Sun Jan 11 13:45:16 2015        Simulation at time: 8.23767 seconds.            
Sun Jan 11 13:45:16 2015        Simulation at time: 8.25745 seconds.            
Sun Jan 11 13:45:16 2015        Writing output file at time: 8.25745 seconds    
Sun Jan 11 13:45:21 2015        Simulation at time: 8.27723 seconds.            
Sun Jan 11 13:45:21 2015        Simulation at time: 8.29701 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.3168 seconds.             
Sun Jan 11 13:45:22 2015        Simulation at time: 8.33659 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.35639 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.37619 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.396 seconds.              
Sun Jan 11 13:45:22 2015        Simulation at time: 8.41581 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.43563 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.45545 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.47528 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.49512 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.51495 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.5348 seconds.             
Sun Jan 11 13:45:22 2015        Simulation at time: 8.55465 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.5745 seconds.             
Sun Jan 11 13:45:22 2015        Simulation at time: 8.59437 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.61424 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.63411 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.654 seconds.              
Sun Jan 11 13:45:22 2015        Simulation at time: 8.67389 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.69378 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.71369 seconds.            
Sun Jan 11 13:45:22 2015        Simulation at time: 8.7336 seconds.             
Sun Jan 11 13:45:23 2015        Simulation at time: 8.75352 seconds.            
Sun Jan 11 13:45:23 2015        Simulation at time: 8.77345 seconds.            
Sun Jan 11 13:45:23 2015        Simulation at time: 8.79339 seconds.            
Sun Jan 11 13:45:23 2015        Simulation at time: 8.81334 seconds.            
Sun Jan 11 13:45:23 2015        Simulation at time: 8.83329 seconds.            
Sun Jan 11 13:45:23 2015        Simulation at time: 8.85326 seconds.            
Sun Jan 11 13:45:23 2015        Simulation at time: 8.87323 seconds.            
Sun Jan 11 13:45:23 2015        Simulation at time: 8.89322 seconds.            
Sun Jan 11 13:45:23 2015        Simulation at time: 8.91321 seconds.            
Sun Jan 11 13:45:23 2015        Simulation at time: 8.93322 seconds.            
Sun Jan 11 13:45:23 2015        Simulation at time: 8.95324 seconds.            
Sun Jan 11 13:45:23 2015        Simulation at time: 8.97327 seconds.            
Sun Jan 11 13:45:23 2015        Simulation at time: 8.99331 seconds.            
Sun Jan 11 13:45:23 2015        Simulation at time: 9.01336 seconds.            
Sun Jan 11 13:45:23 2015        Writing output file at time: 9.01336 seconds    
Sun Jan 11 13:45:29 2015        Simulation at time: 9.03343 seconds.            
Sun Jan 11 13:45:29 2015        Simulation at time: 9.05351 seconds.            
Sun Jan 11 13:45:29 2015        Simulation at time: 9.0736 seconds.             
Sun Jan 11 13:45:29 2015        Simulation at time: 9.09371 seconds.            
Sun Jan 11 13:45:29 2015        Simulation at time: 9.11383 seconds.            
Sun Jan 11 13:45:29 2015        Simulation at time: 9.13397 seconds.            
Sun Jan 11 13:45:29 2015        Simulation at time: 9.15413 seconds.            
Sun Jan 11 13:45:29 2015        Simulation at time: 9.1743 seconds.             
Sun Jan 11 13:45:30 2015        Simulation at time: 9.19449 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.21469 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.23492 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.25516 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.27543 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.29571 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.31602 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.33635 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.3567 seconds.             
Sun Jan 11 13:45:30 2015        Simulation at time: 9.37708 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.39748 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.41791 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.43836 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.45884 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.47935 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.49989 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.52046 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.54106 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.5617 seconds.             
Sun Jan 11 13:45:30 2015        Simulation at time: 9.58236 seconds.            
Sun Jan 11 13:45:30 2015        Simulation at time: 9.60306 seconds.            
Sun Jan 11 13:45:31 2015        Simulation at time: 9.6238 seconds.             
Sun Jan 11 13:45:31 2015        Simulation at time: 9.64457 seconds.            
Sun Jan 11 13:45:31 2015        Simulation at time: 9.66538 seconds.            
Sun Jan 11 13:45:31 2015        Simulation at time: 9.68623 seconds.            
Sun Jan 11 13:45:31 2015        Simulation at time: 9.70711 seconds.            
Sun Jan 11 13:45:31 2015        Simulation at time: 9.72804 seconds.            
Sun Jan 11 13:45:31 2015        Simulation at time: 9.749 seconds.              
Sun Jan 11 13:45:31 2015        Simulation at time: 9.77001 seconds.            
Sun Jan 11 13:45:31 2015        Writing output file at time: 9.77001 seconds    
Sun Jan 11 13:45:36 2015        Simulation at time: 9.79106 seconds.            
Sun Jan 11 13:45:36 2015        Simulation at time: 9.81215 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 9.83326 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 9.85439 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 9.87553 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 9.89668 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 9.91785 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 9.93903 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 9.96022 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 9.98142 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 10.0026 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 10.0239 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 10.0451 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 10.0664 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 10.0876 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 10.1089 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 10.1302 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 10.1515 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 10.1728 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 10.1941 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 10.2154 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 10.2367 seconds.            
Sun Jan 11 13:45:37 2015        Simulation at time: 10.258 seconds.             
Sun Jan 11 13:45:38 2015        Simulation at time: 10.2794 seconds.            
Sun Jan 11 13:45:38 2015        Simulation at time: 10.3007 seconds.            
Sun Jan 11 13:45:38 2015        Simulation at time: 10.322 seconds.             
Sun Jan 11 13:45:38 2015        Simulation at time: 10.3434 seconds.            
Sun Jan 11 13:45:38 2015        Simulation at time: 10.3647 seconds.            
Sun Jan 11 13:45:38 2015        Simulation at time: 10.3861 seconds.            
Sun Jan 11 13:45:38 2015        Simulation at time: 10.4074 seconds.            
Sun Jan 11 13:45:38 2015        Simulation at time: 10.4288 seconds.            
Sun Jan 11 13:45:38 2015        Simulation at time: 10.4501 seconds.            
Sun Jan 11 13:45:38 2015        Simulation at time: 10.4715 seconds.            
Sun Jan 11 13:45:38 2015        Simulation at time: 10.4929 seconds.            
Sun Jan 11 13:45:38 2015        Simulation at time: 10.5142 seconds.            
Sun Jan 11 13:45:38 2015        Writing output file at time: 10.5142 seconds    
Sun Jan 11 13:45:44 2015        Simulation at time: 10.5356 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.557 seconds.             
Sun Jan 11 13:45:44 2015        Simulation at time: 10.5783 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.5997 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.6211 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.6425 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.6639 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.6853 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.7067 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.7281 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.7495 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.7709 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.7923 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.8137 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.8351 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.8566 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.878 seconds.             
Sun Jan 11 13:45:44 2015        Simulation at time: 10.8994 seconds.            
Sun Jan 11 13:45:44 2015        Simulation at time: 10.9209 seconds.            
Sun Jan 11 13:45:45 2015        Simulation at time: 10.9423 seconds.            
Sun Jan 11 13:45:45 2015        Simulation at time: 10.9637 seconds.            
Sun Jan 11 13:45:45 2015        Simulation at time: 10.9852 seconds.            
Sun Jan 11 13:45:45 2015        Simulation at time: 11.0066 seconds.            
Sun Jan 11 13:45:45 2015        Simulation at time: 11.0281 seconds.            
Sun Jan 11 13:45:45 2015        Simulation at time: 11.0495 seconds.            
Sun Jan 11 13:45:45 2015        Simulation at time: 11.071 seconds.             
Sun Jan 11 13:45:45 2015        Simulation at time: 11.0924 seconds.            
Sun Jan 11 13:45:45 2015        Simulation at time: 11.1139 seconds.            
Sun Jan 11 13:45:45 2015        Simulation at time: 11.1353 seconds.            
Sun Jan 11 13:45:45 2015        Simulation at time: 11.1568 seconds.            
Sun Jan 11 13:45:45 2015        Simulation at time: 11.1783 seconds.            
Sun Jan 11 13:45:45 2015        Simulation at time: 11.1998 seconds.            
Sun Jan 11 13:45:45 2015        Simulation at time: 11.2212 seconds.            
Sun Jan 11 13:45:45 2015        Simulation at time: 11.2427 seconds.            
Sun Jan 11 13:45:45 2015        Simulation at time: 11.2642 seconds.            
Sun Jan 11 13:45:45 2015        Writing output file at time: 11.2642 seconds    
Sun Jan 11 13:45:51 2015        Simulation at time: 11.2857 seconds.            
Sun Jan 11 13:45:51 2015        Simulation at time: 11.3072 seconds.            
Sun Jan 11 13:45:51 2015        Simulation at time: 11.3287 seconds.            
Sun Jan 11 13:45:51 2015        Simulation at time: 11.3502 seconds.            
Sun Jan 11 13:45:51 2015        Simulation at time: 11.3717 seconds.            
Sun Jan 11 13:45:51 2015        Simulation at time: 11.3932 seconds.            
Sun Jan 11 13:45:51 2015        Simulation at time: 11.4147 seconds.            
Sun Jan 11 13:45:51 2015        Simulation at time: 11.4362 seconds.            
Sun Jan 11 13:45:51 2015        Simulation at time: 11.4577 seconds.            
Sun Jan 11 13:45:51 2015        Simulation at time: 11.4792 seconds.            
Sun Jan 11 13:45:51 2015        Simulation at time: 11.5007 seconds.            
Sun Jan 11 13:45:51 2015        Simulation at time: 11.5222 seconds.            
Sun Jan 11 13:45:51 2015        Simulation at time: 11.5438 seconds.            
Sun Jan 11 13:45:51 2015        Simulation at time: 11.5653 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.5868 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.6084 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.6299 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.6514 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.673 seconds.             
Sun Jan 11 13:45:52 2015        Simulation at time: 11.6945 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.7161 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.7376 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.7592 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.7807 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.8023 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.8238 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.8454 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.867 seconds.             
Sun Jan 11 13:45:52 2015        Simulation at time: 11.8885 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.9101 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.9317 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.9532 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.9748 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 11.9964 seconds.            
Sun Jan 11 13:45:52 2015        Simulation at time: 12.018 seconds.             
Sun Jan 11 13:45:52 2015        Writing output file at time: 12.018 seconds     
Sun Jan 11 13:45:59 2015        Simulation at time: 12.0396 seconds.            
Sun Jan 11 13:45:59 2015        Simulation at time: 12.0612 seconds.            
Sun Jan 11 13:45:59 2015        Simulation at time: 12.0827 seconds.            
Sun Jan 11 13:45:59 2015        Simulation at time: 12.1043 seconds.            
Sun Jan 11 13:45:59 2015        Simulation at time: 12.1259 seconds.            
Sun Jan 11 13:45:59 2015        Simulation at time: 12.1475 seconds.            
Sun Jan 11 13:45:59 2015        Simulation at time: 12.1691 seconds.            
Sun Jan 11 13:45:59 2015        Simulation at time: 12.1907 seconds.            
Sun Jan 11 13:45:59 2015        Simulation at time: 12.2124 seconds.            
Sun Jan 11 13:45:59 2015        Simulation at time: 12.234 seconds.             
Sun Jan 11 13:45:59 2015        Simulation at time: 12.2556 seconds.            
Sun Jan 11 13:45:59 2015        Simulation at time: 12.2772 seconds.            
Sun Jan 11 13:45:59 2015        Simulation at time: 12.2988 seconds.            
Sun Jan 11 13:45:59 2015        Simulation at time: 12.3204 seconds.            
Sun Jan 11 13:45:59 2015        Simulation at time: 12.342 seconds.             
Sun Jan 11 13:46:00 2015        Simulation at time: 12.3637 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.3853 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.4069 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.4286 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.4502 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.4718 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.4935 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.5151 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.5368 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.5584 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.5801 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.6017 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.6234 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.645 seconds.             
Sun Jan 11 13:46:00 2015        Simulation at time: 12.6667 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.6883 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.71 seconds.              
Sun Jan 11 13:46:00 2015        Simulation at time: 12.7317 seconds.            
Sun Jan 11 13:46:00 2015        Simulation at time: 12.7533 seconds.            
Sun Jan 11 13:46:00 2015        Writing output file at time: 12.7533 seconds    
Sun Jan 11 13:46:06 2015        Simulation at time: 12.775 seconds.             
Sun Jan 11 13:46:06 2015        Simulation at time: 12.7967 seconds.            
Sun Jan 11 13:46:06 2015        Simulation at time: 12.8184 seconds.            
Sun Jan 11 13:46:06 2015        Simulation at time: 12.8401 seconds.            
Sun Jan 11 13:46:06 2015        Simulation at time: 12.8617 seconds.            
Sun Jan 11 13:46:06 2015        Simulation at time: 12.8834 seconds.            
Sun Jan 11 13:46:06 2015        Simulation at time: 12.9051 seconds.            
Sun Jan 11 13:46:06 2015        Simulation at time: 12.9268 seconds.            
Sun Jan 11 13:46:06 2015        Simulation at time: 12.9485 seconds.            
Sun Jan 11 13:46:06 2015        Simulation at time: 12.9702 seconds.            
Sun Jan 11 13:46:06 2015        Simulation at time: 12.9919 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.0136 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.0353 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.057 seconds.             
Sun Jan 11 13:46:07 2015        Simulation at time: 13.0787 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.1004 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.1221 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.1438 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.1655 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.1872 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.2089 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.2307 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.2524 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.2741 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.2958 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.3176 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.3393 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.361 seconds.             
Sun Jan 11 13:46:07 2015        Simulation at time: 13.3828 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.4045 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.4262 seconds.            
Sun Jan 11 13:46:07 2015        Simulation at time: 13.448 seconds.             
Sun Jan 11 13:46:08 2015        Simulation at time: 13.4697 seconds.            
Sun Jan 11 13:46:08 2015        Simulation at time: 13.4915 seconds.            
Sun Jan 11 13:46:08 2015        Simulation at time: 13.5132 seconds.            
Sun Jan 11 13:46:08 2015        Writing output file at time: 13.5132 seconds    
Sun Jan 11 13:46:13 2015        Simulation at time: 13.535 seconds.             
Sun Jan 11 13:46:13 2015        Simulation at time: 13.5567 seconds.            
Sun Jan 11 13:46:13 2015        Simulation at time: 13.5785 seconds.            
Sun Jan 11 13:46:13 2015        Simulation at time: 13.6002 seconds.            
Sun Jan 11 13:46:13 2015        Simulation at time: 13.622 seconds.             
Sun Jan 11 13:46:13 2015        Simulation at time: 13.6437 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 13.6655 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 13.6873 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 13.709 seconds.             
Sun Jan 11 13:46:14 2015        Simulation at time: 13.7308 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 13.7526 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 13.7743 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 13.7961 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 13.8179 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 13.8396 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 13.8614 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 13.8832 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 13.905 seconds.             
Sun Jan 11 13:46:14 2015        Simulation at time: 13.9268 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 13.9486 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 13.9704 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 13.9921 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 14.0139 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 14.0357 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 14.0575 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 14.0793 seconds.            
Sun Jan 11 13:46:14 2015        Simulation at time: 14.1011 seconds.            
Sun Jan 11 13:46:15 2015        Simulation at time: 14.1229 seconds.            
Sun Jan 11 13:46:15 2015        Simulation at time: 14.1447 seconds.            
Sun Jan 11 13:46:15 2015        Simulation at time: 14.1665 seconds.            
Sun Jan 11 13:46:15 2015        Simulation at time: 14.1884 seconds.            
Sun Jan 11 13:46:15 2015        Simulation at time: 14.2102 seconds.            
Sun Jan 11 13:46:15 2015        Simulation at time: 14.232 seconds.             
Sun Jan 11 13:46:15 2015        Simulation at time: 14.2538 seconds.            
Sun Jan 11 13:46:15 2015        Writing output file at time: 14.2538 seconds    
Sun Jan 11 13:46:20 2015        Simulation at time: 14.2756 seconds.            
Sun Jan 11 13:46:20 2015        Simulation at time: 14.2974 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.3193 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.3411 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.3629 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.3847 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.4066 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.4284 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.4502 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.4721 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.4939 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.5157 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.5376 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.5594 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.5813 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.6031 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.625 seconds.             
Sun Jan 11 13:46:21 2015        Simulation at time: 14.6468 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.6687 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.6905 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.7124 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.7342 seconds.            
Sun Jan 11 13:46:21 2015        Simulation at time: 14.7561 seconds.            
Sun Jan 11 13:46:22 2015        Simulation at time: 14.7779 seconds.            
Sun Jan 11 13:46:22 2015        Simulation at time: 14.7998 seconds.            
Sun Jan 11 13:46:22 2015        Simulation at time: 14.8217 seconds.            
Sun Jan 11 13:46:22 2015        Simulation at time: 14.8435 seconds.            
Sun Jan 11 13:46:22 2015        Simulation at time: 14.8654 seconds.            
Sun Jan 11 13:46:22 2015        Simulation at time: 14.8873 seconds.            
Sun Jan 11 13:46:22 2015        Simulation at time: 14.9092 seconds.            
Sun Jan 11 13:46:22 2015        Simulation at time: 14.931 seconds.             
Sun Jan 11 13:46:22 2015        Simulation at time: 14.9529 seconds.            
Sun Jan 11 13:46:22 2015        Simulation at time: 14.9748 seconds.            
Sun Jan 11 13:46:22 2015        Simulation at time: 14.9967 seconds.            
Sun Jan 11 13:46:22 2015        Simulation at time: 15.0186 seconds.            
Sun Jan 11 13:46:22 2015        Writing output file at time: 15.0186 seconds    
                                                                                
------------------------------------------------------------------
Sun Jan 11 13:46:28 2015	Simulation finished. Printing statistics for each process.
------------------------------------------------------------------
Sun Jan 11 13:46:28 2015	process 0 - CPU time: 136.27 seconds
Sun Jan 11 13:46:28 2015	process 0 - wall clock time: 148 seconds
Sun Jan 11 13:46:28 2015	733 iterations done

*************************************************************
SWE finished successfully.
*************************************************************

real	2m38.049s
user	2m37.162s
sys	1m55.759s

*************************************************************
Welcome to SWE

SWE Copyright (C) 2012-2013
  Technische Universitaet Muenchen
  Department of Informatics
  Chair of Scientific Computing
  http://www5.in.tum.de/SWE

SWE comes with ABSOLUTELY NO WARRANTY.
SWE is free software, and you are welcome to redistribute it
under certain conditions.
Details can be found in the file 'gpl.txt'.
*************************************************************
Sun Jan 11 13:46:29 2015	Writing output file at time: 0 seconds
                                                                                
------------------------------------------------------------------
Sun Jan 11 13:46:38 2015	Everything is set up, starting the simulation.
------------------------------------------------------------------
Sun Jan 11 13:46:38 2015        Simulation at time: 0.0219831 seconds.          
Sun Jan 11 13:46:38 2015        Simulation at time: 0.0432806 seconds.          
Sun Jan 11 13:46:38 2015        Simulation at time: 0.0642069 seconds.          
Sun Jan 11 13:46:38 2015        Simulation at time: 0.0848982 seconds.          
Sun Jan 11 13:46:38 2015        Simulation at time: 0.105438 seconds.           
Sun Jan 11 13:46:38 2015        Simulation at time: 0.125793 seconds.           
Sun Jan 11 13:46:38 2015        Simulation at time: 0.146023 seconds.           
Sun Jan 11 13:46:38 2015        Simulation at time: 0.166186 seconds.           
Sun Jan 11 13:46:38 2015        Simulation at time: 0.186302 seconds.           
Sun Jan 11 13:46:38 2015        Simulation at time: 0.206399 seconds.           
Sun Jan 11 13:46:38 2015        Simulation at time: 0.226492 seconds.           
Sun Jan 11 13:46:38 2015        Simulation at time: 0.246591 seconds.           
Sun Jan 11 13:46:38 2015        Simulation at time: 0.266673 seconds.           
Sun Jan 11 13:46:38 2015        Simulation at time: 0.286752 seconds.           
Sun Jan 11 13:46:38 2015        Simulation at time: 0.306841 seconds.           
Sun Jan 11 13:46:38 2015        Simulation at time: 0.326948 seconds.           
Sun Jan 11 13:46:38 2015        Simulation at time: 0.347074 seconds.           
Sun Jan 11 13:46:38 2015        Simulation at time: 0.367217 seconds.           
Sun Jan 11 13:46:38 2015        Simulation at time: 0.387362 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.407508 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.427655 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.447803 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.467952 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.488099 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.508247 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.528394 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.548542 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.568689 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.588834 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.608978 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.629122 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.649266 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.669409 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.68955 seconds.            
Sun Jan 11 13:46:39 2015        Simulation at time: 0.70969 seconds.            
Sun Jan 11 13:46:39 2015        Simulation at time: 0.729831 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.749971 seconds.           
Sun Jan 11 13:46:39 2015        Simulation at time: 0.770112 seconds.           
Sun Jan 11 13:46:39 2015        Writing output file at time: 0.770112 seconds   
Sun Jan 11 13:46:44 2015        Simulation at time: 0.790251 seconds.           
Sun Jan 11 13:46:44 2015        Simulation at time: 0.810388 seconds.           
Sun Jan 11 13:46:44 2015        Simulation at time: 0.830525 seconds.           
Sun Jan 11 13:46:44 2015        Simulation at time: 0.850662 seconds.           
Sun Jan 11 13:46:44 2015        Simulation at time: 0.870797 seconds.           
Sun Jan 11 13:46:44 2015        Simulation at time: 0.890927 seconds.           
Sun Jan 11 13:46:44 2015        Simulation at time: 0.911055 seconds.           
Sun Jan 11 13:46:44 2015        Simulation at time: 0.931181 seconds.           
Sun Jan 11 13:46:44 2015        Simulation at time: 0.951306 seconds.           
Sun Jan 11 13:46:44 2015        Simulation at time: 0.971428 seconds.           
Sun Jan 11 13:46:44 2015        Simulation at time: 0.991548 seconds.           
Sun Jan 11 13:46:44 2015        Simulation at time: 1.01167 seconds.            
Sun Jan 11 13:46:44 2015        Simulation at time: 1.03178 seconds.            
Sun Jan 11 13:46:44 2015        Simulation at time: 1.0519 seconds.             
Sun Jan 11 13:46:44 2015        Simulation at time: 1.07201 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.09212 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.11223 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.13234 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.15245 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.17256 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.19267 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.21277 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.23288 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.25298 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.27309 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.29319 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.31329 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.33339 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.35349 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.37359 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.39368 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.41378 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.43387 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.45397 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.47406 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.49415 seconds.            
Sun Jan 11 13:46:45 2015        Simulation at time: 1.51424 seconds.            
Sun Jan 11 13:46:45 2015        Writing output file at time: 1.51424 seconds    
Sun Jan 11 13:46:50 2015        Simulation at time: 1.53432 seconds.            
Sun Jan 11 13:46:50 2015        Simulation at time: 1.55441 seconds.            
Sun Jan 11 13:46:50 2015        Simulation at time: 1.5745 seconds.             
Sun Jan 11 13:46:50 2015        Simulation at time: 1.59458 seconds.            
Sun Jan 11 13:46:50 2015        Simulation at time: 1.61466 seconds.            
Sun Jan 11 13:46:50 2015        Simulation at time: 1.63474 seconds.            
Sun Jan 11 13:46:50 2015        Simulation at time: 1.65482 seconds.            
Sun Jan 11 13:46:50 2015        Simulation at time: 1.6749 seconds.             
Sun Jan 11 13:46:50 2015        Simulation at time: 1.69497 seconds.            
Sun Jan 11 13:46:50 2015        Simulation at time: 1.71505 seconds.            
Sun Jan 11 13:46:50 2015        Simulation at time: 1.73512 seconds.            
Sun Jan 11 13:46:50 2015        Simulation at time: 1.75519 seconds.            
Sun Jan 11 13:46:50 2015        Simulation at time: 1.77526 seconds.            
Sun Jan 11 13:46:50 2015        Simulation at time: 1.79533 seconds.            
Sun Jan 11 13:46:50 2015        Simulation at time: 1.8154 seconds.             
Sun Jan 11 13:46:50 2015        Simulation at time: 1.83546 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 1.85553 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 1.87559 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 1.89565 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 1.91571 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 1.93577 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 1.95582 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 1.97588 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 1.99593 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 2.01598 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 2.03603 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 2.05608 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 2.07613 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 2.09617 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 2.11622 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 2.13626 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 2.1563 seconds.             
Sun Jan 11 13:46:51 2015        Simulation at time: 2.17634 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 2.19637 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 2.21641 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 2.23644 seconds.            
Sun Jan 11 13:46:51 2015        Simulation at time: 2.25647 seconds.            
Sun Jan 11 13:46:51 2015        Writing output file at time: 2.25647 seconds    
Sun Jan 11 13:46:56 2015        Simulation at time: 2.2765 seconds.             
Sun Jan 11 13:46:56 2015        Simulation at time: 2.29653 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.31656 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.33658 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.35661 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.37663 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.39665 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.41667 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.43668 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.4567 seconds.             
Sun Jan 11 13:46:56 2015        Simulation at time: 2.47671 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.49672 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.51673 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.53674 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.55675 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.57675 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.59676 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.61676 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.63676 seconds.            
Sun Jan 11 13:46:56 2015        Simulation at time: 2.65676 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.67675 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.69675 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.71674 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.73674 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.75673 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.77671 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.7967 seconds.             
Sun Jan 11 13:46:57 2015        Simulation at time: 2.81669 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.83667 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.85665 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.87663 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.89661 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.91659 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.93656 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.95654 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.97651 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 2.99648 seconds.            
Sun Jan 11 13:46:57 2015        Simulation at time: 3.01645 seconds.            
Sun Jan 11 13:46:57 2015        Writing output file at time: 3.01645 seconds    
Sun Jan 11 13:47:03 2015        Simulation at time: 3.03642 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.05638 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.07634 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.09631 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.11627 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.13623 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.15618 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.17614 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.19609 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.21604 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.236 seconds.              
Sun Jan 11 13:47:03 2015        Simulation at time: 3.25594 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.27589 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.29584 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.31578 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.33572 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.35566 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.3756 seconds.             
Sun Jan 11 13:47:03 2015        Simulation at time: 3.39554 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.41547 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.43541 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.45534 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.47527 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.49519 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.51512 seconds.            
Sun Jan 11 13:47:03 2015        Simulation at time: 3.53505 seconds.            
Sun Jan 11 13:47:04 2015        Simulation at time: 3.55497 seconds.            
Sun Jan 11 13:47:04 2015        Simulation at time: 3.57489 seconds.            
Sun Jan 11 13:47:04 2015        Simulation at time: 3.59481 seconds.            
Sun Jan 11 13:47:04 2015        Simulation at time: 3.61473 seconds.            
Sun Jan 11 13:47:04 2015        Simulation at time: 3.63464 seconds.            
Sun Jan 11 13:47:04 2015        Simulation at time: 3.65456 seconds.            
Sun Jan 11 13:47:04 2015        Simulation at time: 3.67447 seconds.            
Sun Jan 11 13:47:04 2015        Simulation at time: 3.69438 seconds.            
Sun Jan 11 13:47:04 2015        Simulation at time: 3.71429 seconds.            
Sun Jan 11 13:47:04 2015        Simulation at time: 3.73419 seconds.            
Sun Jan 11 13:47:04 2015        Simulation at time: 3.7541 seconds.             
Sun Jan 11 13:47:04 2015        Writing output file at time: 3.7541 seconds     
Sun Jan 11 13:47:09 2015        Simulation at time: 3.774 seconds.              
Sun Jan 11 13:47:09 2015        Simulation at time: 3.7939 seconds.             
Sun Jan 11 13:47:09 2015        Simulation at time: 3.8138 seconds.             
Sun Jan 11 13:47:09 2015        Simulation at time: 3.8337 seconds.             
Sun Jan 11 13:47:09 2015        Simulation at time: 3.85359 seconds.            
Sun Jan 11 13:47:09 2015        Simulation at time: 3.87349 seconds.            
Sun Jan 11 13:47:09 2015        Simulation at time: 3.89338 seconds.            
Sun Jan 11 13:47:09 2015        Simulation at time: 3.91327 seconds.            
Sun Jan 11 13:47:09 2015        Simulation at time: 3.93316 seconds.            
Sun Jan 11 13:47:09 2015        Simulation at time: 3.95304 seconds.            
Sun Jan 11 13:47:09 2015        Simulation at time: 3.97293 seconds.            
Sun Jan 11 13:47:09 2015        Simulation at time: 3.99281 seconds.            
Sun Jan 11 13:47:09 2015        Simulation at time: 4.01269 seconds.            
Sun Jan 11 13:47:09 2015        Simulation at time: 4.03257 seconds.            
Sun Jan 11 13:47:09 2015        Simulation at time: 4.05245 seconds.            
Sun Jan 11 13:47:09 2015        Simulation at time: 4.07232 seconds.            
Sun Jan 11 13:47:09 2015        Simulation at time: 4.0922 seconds.             
Sun Jan 11 13:47:09 2015        Simulation at time: 4.11207 seconds.            
Sun Jan 11 13:47:09 2015        Simulation at time: 4.13194 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.1518 seconds.             
Sun Jan 11 13:47:10 2015        Simulation at time: 4.17167 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.19153 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.21139 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.23125 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.25111 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.27097 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.29082 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.31067 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.33053 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.35037 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.37022 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.39006 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.40991 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.42975 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.44959 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.46943 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.48926 seconds.            
Sun Jan 11 13:47:10 2015        Simulation at time: 4.50909 seconds.            
Sun Jan 11 13:47:10 2015        Writing output file at time: 4.50909 seconds    
Sun Jan 11 13:47:15 2015        Simulation at time: 4.52893 seconds.            
Sun Jan 11 13:47:15 2015        Simulation at time: 4.54876 seconds.            
Sun Jan 11 13:47:15 2015        Simulation at time: 4.56858 seconds.            
Sun Jan 11 13:47:15 2015        Simulation at time: 4.58841 seconds.            
Sun Jan 11 13:47:15 2015        Simulation at time: 4.60823 seconds.            
Sun Jan 11 13:47:15 2015        Simulation at time: 4.62806 seconds.            
Sun Jan 11 13:47:15 2015        Simulation at time: 4.64788 seconds.            
Sun Jan 11 13:47:15 2015        Simulation at time: 4.6677 seconds.             
Sun Jan 11 13:47:15 2015        Simulation at time: 4.68751 seconds.            
Sun Jan 11 13:47:15 2015        Simulation at time: 4.70733 seconds.            
Sun Jan 11 13:47:15 2015        Simulation at time: 4.72714 seconds.            
Sun Jan 11 13:47:15 2015        Simulation at time: 4.74695 seconds.            
Sun Jan 11 13:47:15 2015        Simulation at time: 4.76676 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 4.78657 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 4.80638 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 4.82618 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 4.84598 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 4.86578 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 4.88558 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 4.90538 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 4.92517 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 4.94497 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 4.96476 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 4.98455 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 5.00434 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 5.02412 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 5.04391 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 5.06369 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 5.08348 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 5.10325 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 5.12303 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 5.14281 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 5.16259 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 5.18236 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 5.20213 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 5.2219 seconds.             
Sun Jan 11 13:47:16 2015        Simulation at time: 5.24167 seconds.            
Sun Jan 11 13:47:16 2015        Simulation at time: 5.26144 seconds.            
Sun Jan 11 13:47:16 2015        Writing output file at time: 5.26144 seconds    
Sun Jan 11 13:47:21 2015        Simulation at time: 5.2812 seconds.             
Sun Jan 11 13:47:21 2015        Simulation at time: 5.30097 seconds.            
Sun Jan 11 13:47:21 2015        Simulation at time: 5.32073 seconds.            
Sun Jan 11 13:47:21 2015        Simulation at time: 5.34049 seconds.            
Sun Jan 11 13:47:21 2015        Simulation at time: 5.36025 seconds.            
Sun Jan 11 13:47:21 2015        Simulation at time: 5.38001 seconds.            
Sun Jan 11 13:47:21 2015        Simulation at time: 5.39976 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.41952 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.43927 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.45902 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.47877 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.49852 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.51827 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.53801 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.55775 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.5775 seconds.             
Sun Jan 11 13:47:22 2015        Simulation at time: 5.59724 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.61698 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.63672 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.65645 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.67619 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.69592 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.71566 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.73539 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.75512 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.77485 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.79458 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.8143 seconds.             
Sun Jan 11 13:47:22 2015        Simulation at time: 5.83403 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.85375 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.87347 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.89319 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.91291 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.93263 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.95235 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.97207 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 5.99178 seconds.            
Sun Jan 11 13:47:22 2015        Simulation at time: 6.01149 seconds.            
Sun Jan 11 13:47:22 2015        Writing output file at time: 6.01149 seconds    
Sun Jan 11 13:47:27 2015        Simulation at time: 6.03121 seconds.            
Sun Jan 11 13:47:27 2015        Simulation at time: 6.05092 seconds.            
Sun Jan 11 13:47:27 2015        Simulation at time: 6.07063 seconds.            
Sun Jan 11 13:47:27 2015        Simulation at time: 6.09034 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.11005 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.12975 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.14946 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.16916 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.18887 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.20857 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.22827 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.24797 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.26767 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.28737 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.30707 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.32677 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.34646 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.36616 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.38585 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.40555 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.42524 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.44493 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.46462 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.48431 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.504 seconds.              
Sun Jan 11 13:47:28 2015        Simulation at time: 6.52369 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.54338 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.56307 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.58276 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.60244 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.62213 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.64181 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.6615 seconds.             
Sun Jan 11 13:47:28 2015        Simulation at time: 6.68118 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.70087 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.72055 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.74023 seconds.            
Sun Jan 11 13:47:28 2015        Simulation at time: 6.75991 seconds.            
Sun Jan 11 13:47:28 2015        Writing output file at time: 6.75991 seconds    
Sun Jan 11 13:47:34 2015        Simulation at time: 6.7796 seconds.             
Sun Jan 11 13:47:34 2015        Simulation at time: 6.79928 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 6.81896 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 6.83864 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 6.85832 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 6.878 seconds.              
Sun Jan 11 13:47:34 2015        Simulation at time: 6.89768 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 6.91736 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 6.93704 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 6.95672 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 6.9764 seconds.             
Sun Jan 11 13:47:34 2015        Simulation at time: 6.99608 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 7.01576 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 7.03544 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 7.05512 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 7.0748 seconds.             
Sun Jan 11 13:47:34 2015        Simulation at time: 7.09448 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 7.11416 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 7.13384 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 7.15352 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 7.1732 seconds.             
Sun Jan 11 13:47:34 2015        Simulation at time: 7.19288 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 7.21256 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 7.23225 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 7.25193 seconds.            
Sun Jan 11 13:47:34 2015        Simulation at time: 7.27161 seconds.            
Sun Jan 11 13:47:35 2015        Simulation at time: 7.29129 seconds.            
Sun Jan 11 13:47:35 2015        Simulation at time: 7.31098 seconds.            
Sun Jan 11 13:47:35 2015        Simulation at time: 7.33066 seconds.            
Sun Jan 11 13:47:35 2015        Simulation at time: 7.35035 seconds.            
Sun Jan 11 13:47:35 2015        Simulation at time: 7.37003 seconds.            
Sun Jan 11 13:47:35 2015        Simulation at time: 7.38972 seconds.            
Sun Jan 11 13:47:35 2015        Simulation at time: 7.4094 seconds.             
Sun Jan 11 13:47:35 2015        Simulation at time: 7.42909 seconds.            
Sun Jan 11 13:47:35 2015        Simulation at time: 7.44878 seconds.            
Sun Jan 11 13:47:35 2015        Simulation at time: 7.46847 seconds.            
Sun Jan 11 13:47:35 2015        Simulation at time: 7.48816 seconds.            
Sun Jan 11 13:47:35 2015        Simulation at time: 7.50785 seconds.            
Sun Jan 11 13:47:35 2015        Writing output file at time: 7.50785 seconds    
Sun Jan 11 13:47:40 2015        Simulation at time: 7.52754 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.54724 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.56693 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.58663 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.60632 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.62602 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.64572 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.66542 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.68512 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.70483 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.72453 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.74424 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.76395 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.78366 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.80337 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.82309 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.8428 seconds.             
Sun Jan 11 13:47:40 2015        Simulation at time: 7.86252 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.88224 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.90197 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.92169 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.94142 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.96115 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 7.98088 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 8.00062 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 8.02035 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 8.04009 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 8.05984 seconds.            
Sun Jan 11 13:47:40 2015        Simulation at time: 8.07958 seconds.            
Sun Jan 11 13:47:41 2015        Simulation at time: 8.09933 seconds.            
Sun Jan 11 13:47:41 2015        Simulation at time: 8.11908 seconds.            
Sun Jan 11 13:47:41 2015        Simulation at time: 8.13884 seconds.            
Sun Jan 11 13:47:41 2015        Simulation at time: 8.1586 seconds.             
Sun Jan 11 13:47:41 2015        Simulation at time: 8.17836 seconds.            
Sun Jan 11 13:47:41 2015        Simulation at time: 8.19813 seconds.            
Sun Jan 11 13:47:41 2015        Simulation at time: 8.2179 seconds.             
Sun Jan 11 13:47:41 2015        Simulation at time: 8.23767 seconds.            
Sun Jan 11 13:47:41 2015        Simulation at time: 8.25745 seconds.            
Sun Jan 11 13:47:41 2015        Writing output file at time: 8.25745 seconds    
Sun Jan 11 13:47:46 2015        Simulation at time: 8.27723 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.29701 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.3168 seconds.             
Sun Jan 11 13:47:46 2015        Simulation at time: 8.33659 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.35639 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.37619 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.396 seconds.              
Sun Jan 11 13:47:46 2015        Simulation at time: 8.41581 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.43563 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.45545 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.47528 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.49512 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.51495 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.5348 seconds.             
Sun Jan 11 13:47:46 2015        Simulation at time: 8.55465 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.5745 seconds.             
Sun Jan 11 13:47:46 2015        Simulation at time: 8.59437 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.61424 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.63411 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.654 seconds.              
Sun Jan 11 13:47:46 2015        Simulation at time: 8.67389 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.69378 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.71369 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.7336 seconds.             
Sun Jan 11 13:47:46 2015        Simulation at time: 8.75352 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.77345 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.79339 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.81334 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.83329 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.85326 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.87323 seconds.            
Sun Jan 11 13:47:46 2015        Simulation at time: 8.89322 seconds.            
Sun Jan 11 13:47:47 2015        Simulation at time: 8.91321 seconds.            
Sun Jan 11 13:47:47 2015        Simulation at time: 8.93322 seconds.            
Sun Jan 11 13:47:47 2015        Simulation at time: 8.95324 seconds.            
Sun Jan 11 13:47:47 2015        Simulation at time: 8.97327 seconds.            
Sun Jan 11 13:47:47 2015        Simulation at time: 8.99331 seconds.            
Sun Jan 11 13:47:47 2015        Simulation at time: 9.01336 seconds.            
Sun Jan 11 13:47:47 2015        Writing output file at time: 9.01336 seconds    
Sun Jan 11 13:47:52 2015        Simulation at time: 9.03343 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.05351 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.0736 seconds.             
Sun Jan 11 13:47:52 2015        Simulation at time: 9.09371 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.11383 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.13397 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.15413 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.1743 seconds.             
Sun Jan 11 13:47:52 2015        Simulation at time: 9.19449 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.21469 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.23492 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.25516 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.27543 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.29571 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.31602 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.33635 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.3567 seconds.             
Sun Jan 11 13:47:52 2015        Simulation at time: 9.37708 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.39748 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.41791 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.43836 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.45884 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.47935 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.49989 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.52046 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.54106 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.5617 seconds.             
Sun Jan 11 13:47:52 2015        Simulation at time: 9.58236 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.60306 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.6238 seconds.             
Sun Jan 11 13:47:52 2015        Simulation at time: 9.64457 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.66538 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.68623 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.70711 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.72804 seconds.            
Sun Jan 11 13:47:52 2015        Simulation at time: 9.749 seconds.              
Sun Jan 11 13:47:52 2015        Simulation at time: 9.77001 seconds.            
Sun Jan 11 13:47:52 2015        Writing output file at time: 9.77001 seconds    
Sun Jan 11 13:47:57 2015        Simulation at time: 9.79106 seconds.            
Sun Jan 11 13:47:57 2015        Simulation at time: 9.81215 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 9.83326 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 9.85439 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 9.87553 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 9.89668 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 9.91785 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 9.93903 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 9.96022 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 9.98142 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.0026 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.0239 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.0451 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.0664 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.0876 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.1089 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.1302 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.1515 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.1728 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.1941 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.2154 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.2367 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.258 seconds.             
Sun Jan 11 13:47:58 2015        Simulation at time: 10.2794 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.3007 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.322 seconds.             
Sun Jan 11 13:47:58 2015        Simulation at time: 10.3434 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.3647 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.3861 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.4074 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.4288 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.4501 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.4715 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.4929 seconds.            
Sun Jan 11 13:47:58 2015        Simulation at time: 10.5142 seconds.            
Sun Jan 11 13:47:58 2015        Writing output file at time: 10.5142 seconds    
Sun Jan 11 13:48:04 2015        Simulation at time: 10.5356 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.557 seconds.             
Sun Jan 11 13:48:04 2015        Simulation at time: 10.5783 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.5997 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.6211 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.6425 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.6639 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.6853 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.7067 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.7281 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.7495 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.7709 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.7923 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.8137 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.8351 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.8566 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.878 seconds.             
Sun Jan 11 13:48:04 2015        Simulation at time: 10.8994 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.9209 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.9423 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.9637 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 10.9852 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 11.0066 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 11.0281 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 11.0495 seconds.            
Sun Jan 11 13:48:04 2015        Simulation at time: 11.071 seconds.             
Sun Jan 11 13:48:04 2015        Simulation at time: 11.0924 seconds.            
Sun Jan 11 13:48:05 2015        Simulation at time: 11.1139 seconds.            
Sun Jan 11 13:48:05 2015        Simulation at time: 11.1353 seconds.            
Sun Jan 11 13:48:05 2015        Simulation at time: 11.1568 seconds.            
Sun Jan 11 13:48:05 2015        Simulation at time: 11.1783 seconds.            
Sun Jan 11 13:48:05 2015        Simulation at time: 11.1998 seconds.            
Sun Jan 11 13:48:05 2015        Simulation at time: 11.2212 seconds.            
Sun Jan 11 13:48:05 2015        Simulation at time: 11.2427 seconds.            
Sun Jan 11 13:48:05 2015        Simulation at time: 11.2642 seconds.            
Sun Jan 11 13:48:05 2015        Writing output file at time: 11.2642 seconds    
Sun Jan 11 13:48:10 2015        Simulation at time: 11.2857 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.3072 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.3287 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.3502 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.3717 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.3932 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.4147 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.4362 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.4577 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.4792 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.5007 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.5222 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.5438 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.5653 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.5868 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.6084 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.6299 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.6514 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.673 seconds.             
Sun Jan 11 13:48:10 2015        Simulation at time: 11.6945 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.7161 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.7376 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.7592 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.7807 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.8023 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.8238 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.8454 seconds.            
Sun Jan 11 13:48:10 2015        Simulation at time: 11.867 seconds.             
Sun Jan 11 13:48:10 2015        Simulation at time: 11.8885 seconds.            
Sun Jan 11 13:48:11 2015        Simulation at time: 11.9101 seconds.            
Sun Jan 11 13:48:11 2015        Simulation at time: 11.9317 seconds.            
Sun Jan 11 13:48:11 2015        Simulation at time: 11.9532 seconds.            
Sun Jan 11 13:48:11 2015        Simulation at time: 11.9748 seconds.            
Sun Jan 11 13:48:11 2015        Simulation at time: 11.9964 seconds.            
Sun Jan 11 13:48:11 2015        Simulation at time: 12.018 seconds.             
Sun Jan 11 13:48:11 2015        Writing output file at time: 12.018 seconds     
Sun Jan 11 13:48:16 2015        Simulation at time: 12.0396 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.0612 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.0827 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.1043 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.1259 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.1475 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.1691 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.1907 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.2124 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.234 seconds.             
Sun Jan 11 13:48:16 2015        Simulation at time: 12.2556 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.2772 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.2988 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.3204 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.342 seconds.             
Sun Jan 11 13:48:16 2015        Simulation at time: 12.3637 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.3853 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.4069 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.4286 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.4502 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.4718 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.4935 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.5151 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.5368 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.5584 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.5801 seconds.            
Sun Jan 11 13:48:16 2015        Simulation at time: 12.6017 seconds.            
Sun Jan 11 13:48:17 2015        Simulation at time: 12.6234 seconds.            
Sun Jan 11 13:48:17 2015        Simulation at time: 12.645 seconds.             
Sun Jan 11 13:48:17 2015        Simulation at time: 12.6667 seconds.            
Sun Jan 11 13:48:17 2015        Simulation at time: 12.6883 seconds.            
Sun Jan 11 13:48:17 2015        Simulation at time: 12.71 seconds.              
Sun Jan 11 13:48:17 2015        Simulation at time: 12.7317 seconds.            
Sun Jan 11 13:48:17 2015        Simulation at time: 12.7533 seconds.            
Sun Jan 11 13:48:17 2015        Writing output file at time: 12.7533 seconds    
Sun Jan 11 13:48:22 2015        Simulation at time: 12.775 seconds.             
Sun Jan 11 13:48:22 2015        Simulation at time: 12.7967 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 12.8184 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 12.8401 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 12.8617 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 12.8834 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 12.9051 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 12.9268 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 12.9485 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 12.9702 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 12.9919 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.0136 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.0353 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.057 seconds.             
Sun Jan 11 13:48:22 2015        Simulation at time: 13.0787 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.1004 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.1221 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.1438 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.1655 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.1872 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.2089 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.2307 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.2524 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.2741 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.2958 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.3176 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.3393 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.361 seconds.             
Sun Jan 11 13:48:22 2015        Simulation at time: 13.3828 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.4045 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.4262 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.448 seconds.             
Sun Jan 11 13:48:22 2015        Simulation at time: 13.4697 seconds.            
Sun Jan 11 13:48:22 2015        Simulation at time: 13.4915 seconds.            
Sun Jan 11 13:48:23 2015        Simulation at time: 13.5132 seconds.            
Sun Jan 11 13:48:23 2015        Writing output file at time: 13.5132 seconds    
Sun Jan 11 13:48:28 2015        Simulation at time: 13.535 seconds.             
Sun Jan 11 13:48:28 2015        Simulation at time: 13.5567 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.5785 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.6002 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.622 seconds.             
Sun Jan 11 13:48:28 2015        Simulation at time: 13.6437 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.6655 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.6873 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.709 seconds.             
Sun Jan 11 13:48:28 2015        Simulation at time: 13.7308 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.7526 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.7743 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.7961 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.8179 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.8396 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.8614 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.8832 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.905 seconds.             
Sun Jan 11 13:48:28 2015        Simulation at time: 13.9268 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.9486 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.9704 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 13.9921 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 14.0139 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 14.0357 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 14.0575 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 14.0793 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 14.1011 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 14.1229 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 14.1447 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 14.1665 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 14.1884 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 14.2102 seconds.            
Sun Jan 11 13:48:28 2015        Simulation at time: 14.232 seconds.             
Sun Jan 11 13:48:28 2015        Simulation at time: 14.2538 seconds.            
Sun Jan 11 13:48:28 2015        Writing output file at time: 14.2538 seconds    
Sun Jan 11 13:48:34 2015        Simulation at time: 14.2756 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.2974 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.3193 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.3411 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.3629 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.3847 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.4066 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.4284 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.4502 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.4721 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.4939 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.5157 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.5376 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.5594 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.5813 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.6031 seconds.            
Sun Jan 11 13:48:34 2015        Simulation at time: 14.625 seconds.             
Sun Jan 11 13:48:34 2015        Simulation at time: 14.6468 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 14.6687 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 14.6905 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 14.7124 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 14.7342 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 14.7561 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 14.7779 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 14.7998 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 14.8217 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 14.8435 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 14.8654 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 14.8873 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 14.9092 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 14.931 seconds.             
Sun Jan 11 13:48:35 2015        Simulation at time: 14.9529 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 14.9748 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 14.9967 seconds.            
Sun Jan 11 13:48:35 2015        Simulation at time: 15.0186 seconds.            
Sun Jan 11 13:48:35 2015        Writing output file at time: 15.0186 seconds    
                                                                                
------------------------------------------------------------------
Sun Jan 11 13:48:40 2015	Simulation finished. Printing statistics for each process.
------------------------------------------------------------------
Sun Jan 11 13:48:40 2015	process 0 - CPU time: 142.8 seconds
Sun Jan 11 13:48:40 2015	process 0 - wall clock time: 122 seconds
Sun Jan 11 13:48:40 2015	733 iterations done

*************************************************************
SWE finished successfully.
*************************************************************

real	2m11.974s
user	3m8.632s
sys	1m47.047s

*************************************************************
Welcome to SWE

SWE Copyright (C) 2012-2013
  Technische Universitaet Muenchen
  Department of Informatics
  Chair of Scientific Computing
  http://www5.in.tum.de/SWE

SWE comes with ABSOLUTELY NO WARRANTY.
SWE is free software, and you are welcome to redistribute it
under certain conditions.
Details can be found in the file 'gpl.txt'.
*************************************************************
Sun Jan 11 13:48:41 2015	Writing output file at time: 0 seconds
                                                                                
------------------------------------------------------------------
Sun Jan 11 13:48:50 2015	Everything is set up, starting the simulation.
------------------------------------------------------------------
Sun Jan 11 13:48:50 2015        Simulation at time: 0.0219831 seconds.          
Sun Jan 11 13:48:50 2015        Simulation at time: 0.0432806 seconds.          
Sun Jan 11 13:48:50 2015        Simulation at time: 0.0642069 seconds.          
Sun Jan 11 13:48:50 2015        Simulation at time: 0.0848982 seconds.          
Sun Jan 11 13:48:50 2015        Simulation at time: 0.105438 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.125793 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.146023 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.166186 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.186302 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.206399 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.226492 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.246591 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.266673 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.286752 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.306841 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.326948 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.347074 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.367217 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.387362 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.407508 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.427655 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.447803 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.467952 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.488099 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.508247 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.528394 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.548542 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.568689 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.588834 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.608978 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.629122 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.649266 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.669409 seconds.           
Sun Jan 11 13:48:50 2015        Simulation at time: 0.68955 seconds.            
Sun Jan 11 13:48:51 2015        Simulation at time: 0.70969 seconds.            
Sun Jan 11 13:48:51 2015        Simulation at time: 0.729831 seconds.           
Sun Jan 11 13:48:51 2015        Simulation at time: 0.749971 seconds.           
Sun Jan 11 13:48:51 2015        Simulation at time: 0.770112 seconds.           
Sun Jan 11 13:48:51 2015        Writing output file at time: 0.770112 seconds   
Sun Jan 11 13:48:58 2015        Simulation at time: 0.790251 seconds.           
Sun Jan 11 13:48:58 2015        Simulation at time: 0.810388 seconds.           
Sun Jan 11 13:48:58 2015        Simulation at time: 0.830525 seconds.           
Sun Jan 11 13:48:58 2015        Simulation at time: 0.850662 seconds.           
Sun Jan 11 13:48:58 2015        Simulation at time: 0.870797 seconds.           
Sun Jan 11 13:48:58 2015        Simulation at time: 0.890927 seconds.           
Sun Jan 11 13:48:58 2015        Simulation at time: 0.911055 seconds.           
Sun Jan 11 13:48:58 2015        Simulation at time: 0.931181 seconds.           
Sun Jan 11 13:48:58 2015        Simulation at time: 0.951306 seconds.           
Sun Jan 11 13:48:58 2015        Simulation at time: 0.971428 seconds.           
Sun Jan 11 13:48:58 2015        Simulation at time: 0.991548 seconds.           
Sun Jan 11 13:48:58 2015        Simulation at time: 1.01167 seconds.            
Sun Jan 11 13:48:58 2015        Simulation at time: 1.03178 seconds.            
Sun Jan 11 13:48:58 2015        Simulation at time: 1.0519 seconds.             
Sun Jan 11 13:48:58 2015        Simulation at time: 1.07201 seconds.            
Sun Jan 11 13:48:58 2015        Simulation at time: 1.09212 seconds.            
Sun Jan 11 13:48:58 2015        Simulation at time: 1.11223 seconds.            
Sun Jan 11 13:48:58 2015        Simulation at time: 1.13234 seconds.            
Sun Jan 11 13:48:58 2015        Simulation at time: 1.15245 seconds.            
Sun Jan 11 13:48:58 2015        Simulation at time: 1.17256 seconds.            
Sun Jan 11 13:48:58 2015        Simulation at time: 1.19267 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.21277 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.23288 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.25298 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.27309 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.29319 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.31329 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.33339 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.35349 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.37359 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.39368 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.41378 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.43387 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.45397 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.47406 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.49415 seconds.            
Sun Jan 11 13:48:59 2015        Simulation at time: 1.51424 seconds.            
Sun Jan 11 13:48:59 2015        Writing output file at time: 1.51424 seconds    
Sun Jan 11 13:49:06 2015        Simulation at time: 1.53432 seconds.            
Sun Jan 11 13:49:06 2015        Simulation at time: 1.55441 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.5745 seconds.             
Sun Jan 11 13:49:07 2015        Simulation at time: 1.59458 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.61466 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.63474 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.65482 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.6749 seconds.             
Sun Jan 11 13:49:07 2015        Simulation at time: 1.69497 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.71505 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.73512 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.75519 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.77526 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.79533 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.8154 seconds.             
Sun Jan 11 13:49:07 2015        Simulation at time: 1.83546 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.85553 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.87559 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.89565 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.91571 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.93577 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.95582 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.97588 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 1.99593 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 2.01598 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 2.03603 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 2.05608 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 2.07613 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 2.09617 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 2.11622 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 2.13626 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 2.1563 seconds.             
Sun Jan 11 13:49:07 2015        Simulation at time: 2.17634 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 2.19637 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 2.21641 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 2.23644 seconds.            
Sun Jan 11 13:49:07 2015        Simulation at time: 2.25647 seconds.            
Sun Jan 11 13:49:07 2015        Writing output file at time: 2.25647 seconds    
Sun Jan 11 13:49:15 2015        Simulation at time: 2.2765 seconds.             
Sun Jan 11 13:49:15 2015        Simulation at time: 2.29653 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.31656 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.33658 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.35661 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.37663 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.39665 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.41667 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.43668 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.4567 seconds.             
Sun Jan 11 13:49:15 2015        Simulation at time: 2.47671 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.49672 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.51673 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.53674 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.55675 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.57675 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.59676 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.61676 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.63676 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.65676 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.67675 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.69675 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.71674 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.73674 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.75673 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.77671 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.7967 seconds.             
Sun Jan 11 13:49:15 2015        Simulation at time: 2.81669 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.83667 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.85665 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.87663 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.89661 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.91659 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.93656 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.95654 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.97651 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 2.99648 seconds.            
Sun Jan 11 13:49:15 2015        Simulation at time: 3.01645 seconds.            
Sun Jan 11 13:49:15 2015        Writing output file at time: 3.01645 seconds    
Sun Jan 11 13:49:24 2015        Simulation at time: 3.03642 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.05638 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.07634 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.09631 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.11627 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.13623 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.15618 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.17614 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.19609 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.21604 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.236 seconds.              
Sun Jan 11 13:49:24 2015        Simulation at time: 3.25594 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.27589 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.29584 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.31578 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.33572 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.35566 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.3756 seconds.             
Sun Jan 11 13:49:24 2015        Simulation at time: 3.39554 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.41547 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.43541 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.45534 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.47527 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.49519 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.51512 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.53505 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.55497 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.57489 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.59481 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.61473 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.63464 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.65456 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.67447 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.69438 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.71429 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.73419 seconds.            
Sun Jan 11 13:49:24 2015        Simulation at time: 3.7541 seconds.             
Sun Jan 11 13:49:24 2015        Writing output file at time: 3.7541 seconds     
Sun Jan 11 13:49:32 2015        Simulation at time: 3.774 seconds.              
Sun Jan 11 13:49:32 2015        Simulation at time: 3.7939 seconds.             
Sun Jan 11 13:49:32 2015        Simulation at time: 3.8138 seconds.             
Sun Jan 11 13:49:32 2015        Simulation at time: 3.8337 seconds.             
Sun Jan 11 13:49:32 2015        Simulation at time: 3.85359 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 3.87349 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 3.89338 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 3.91327 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 3.93316 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 3.95304 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 3.97293 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 3.99281 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.01269 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.03257 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.05245 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.07232 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.0922 seconds.             
Sun Jan 11 13:49:32 2015        Simulation at time: 4.11207 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.13194 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.1518 seconds.             
Sun Jan 11 13:49:32 2015        Simulation at time: 4.17167 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.19153 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.21139 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.23125 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.25111 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.27097 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.29082 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.31067 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.33053 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.35037 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.37022 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.39006 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.40991 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.42975 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.44959 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.46943 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.48926 seconds.            
Sun Jan 11 13:49:32 2015        Simulation at time: 4.50909 seconds.            
Sun Jan 11 13:49:32 2015        Writing output file at time: 4.50909 seconds    
Sun Jan 11 13:49:40 2015        Simulation at time: 4.52893 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.54876 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.56858 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.58841 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.60823 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.62806 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.64788 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.6677 seconds.             
Sun Jan 11 13:49:40 2015        Simulation at time: 4.68751 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.70733 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.72714 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.74695 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.76676 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.78657 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.80638 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.82618 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.84598 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.86578 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.88558 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.90538 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.92517 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.94497 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.96476 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 4.98455 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 5.00434 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 5.02412 seconds.            
Sun Jan 11 13:49:40 2015        Simulation at time: 5.04391 seconds.            
Sun Jan 11 13:49:41 2015        Simulation at time: 5.06369 seconds.            
Sun Jan 11 13:49:41 2015        Simulation at time: 5.08348 seconds.            
Sun Jan 11 13:49:41 2015        Simulation at time: 5.10325 seconds.            
Sun Jan 11 13:49:41 2015        Simulation at time: 5.12303 seconds.            
Sun Jan 11 13:49:41 2015        Simulation at time: 5.14281 seconds.            
Sun Jan 11 13:49:41 2015        Simulation at time: 5.16259 seconds.            
Sun Jan 11 13:49:41 2015        Simulation at time: 5.18236 seconds.            
Sun Jan 11 13:49:41 2015        Simulation at time: 5.20213 seconds.            
Sun Jan 11 13:49:41 2015        Simulation at time: 5.2219 seconds.             
Sun Jan 11 13:49:41 2015        Simulation at time: 5.24167 seconds.            
Sun Jan 11 13:49:41 2015        Simulation at time: 5.26144 seconds.            
Sun Jan 11 13:49:41 2015        Writing output file at time: 5.26144 seconds    
Sun Jan 11 13:49:49 2015        Simulation at time: 5.2812 seconds.             
Sun Jan 11 13:49:49 2015        Simulation at time: 5.30097 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.32073 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.34049 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.36025 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.38001 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.39976 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.41952 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.43927 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.45902 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.47877 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.49852 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.51827 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.53801 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.55775 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.5775 seconds.             
Sun Jan 11 13:49:49 2015        Simulation at time: 5.59724 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.61698 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.63672 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.65645 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.67619 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.69592 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.71566 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.73539 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.75512 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.77485 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.79458 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.8143 seconds.             
Sun Jan 11 13:49:49 2015        Simulation at time: 5.83403 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.85375 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.87347 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.89319 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.91291 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.93263 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.95235 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.97207 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 5.99178 seconds.            
Sun Jan 11 13:49:49 2015        Simulation at time: 6.01149 seconds.            
Sun Jan 11 13:49:49 2015        Writing output file at time: 6.01149 seconds    
Sun Jan 11 13:49:57 2015        Simulation at time: 6.03121 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.05092 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.07063 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.09034 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.11005 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.12975 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.14946 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.16916 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.18887 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.20857 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.22827 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.24797 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.26767 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.28737 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.30707 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.32677 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.34646 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.36616 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.38585 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.40555 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.42524 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.44493 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.46462 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.48431 seconds.            
Sun Jan 11 13:49:57 2015        Simulation at time: 6.504 seconds.              
Sun Jan 11 13:49:58 2015        Simulation at time: 6.52369 seconds.            
Sun Jan 11 13:49:58 2015        Simulation at time: 6.54338 seconds.            
Sun Jan 11 13:49:58 2015        Simulation at time: 6.56307 seconds.            
Sun Jan 11 13:49:58 2015        Simulation at time: 6.58276 seconds.            
Sun Jan 11 13:49:58 2015        Simulation at time: 6.60244 seconds.            
Sun Jan 11 13:49:58 2015        Simulation at time: 6.62213 seconds.            
Sun Jan 11 13:49:58 2015        Simulation at time: 6.64181 seconds.            
Sun Jan 11 13:49:58 2015        Simulation at time: 6.6615 seconds.             
Sun Jan 11 13:49:58 2015        Simulation at time: 6.68118 seconds.            
Sun Jan 11 13:49:58 2015        Simulation at time: 6.70087 seconds.            
Sun Jan 11 13:49:58 2015        Simulation at time: 6.72055 seconds.            
Sun Jan 11 13:49:58 2015        Simulation at time: 6.74023 seconds.            
Sun Jan 11 13:49:58 2015        Simulation at time: 6.75991 seconds.            
Sun Jan 11 13:49:58 2015        Writing output file at time: 6.75991 seconds    
Sun Jan 11 13:50:05 2015        Simulation at time: 6.7796 seconds.             
Sun Jan 11 13:50:05 2015        Simulation at time: 6.79928 seconds.            
Sun Jan 11 13:50:05 2015        Simulation at time: 6.81896 seconds.            
Sun Jan 11 13:50:05 2015        Simulation at time: 6.83864 seconds.            
Sun Jan 11 13:50:05 2015        Simulation at time: 6.85832 seconds.            
Sun Jan 11 13:50:05 2015        Simulation at time: 6.878 seconds.              
Sun Jan 11 13:50:05 2015        Simulation at time: 6.89768 seconds.            
Sun Jan 11 13:50:05 2015        Simulation at time: 6.91736 seconds.            
Sun Jan 11 13:50:05 2015        Simulation at time: 6.93704 seconds.            
Sun Jan 11 13:50:05 2015        Simulation at time: 6.95672 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 6.9764 seconds.             
Sun Jan 11 13:50:06 2015        Simulation at time: 6.99608 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.01576 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.03544 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.05512 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.0748 seconds.             
Sun Jan 11 13:50:06 2015        Simulation at time: 7.09448 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.11416 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.13384 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.15352 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.1732 seconds.             
Sun Jan 11 13:50:06 2015        Simulation at time: 7.19288 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.21256 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.23225 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.25193 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.27161 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.29129 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.31098 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.33066 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.35035 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.37003 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.38972 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.4094 seconds.             
Sun Jan 11 13:50:06 2015        Simulation at time: 7.42909 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.44878 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.46847 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.48816 seconds.            
Sun Jan 11 13:50:06 2015        Simulation at time: 7.50785 seconds.            
Sun Jan 11 13:50:06 2015        Writing output file at time: 7.50785 seconds    
Sun Jan 11 13:50:14 2015        Simulation at time: 7.52754 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.54724 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.56693 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.58663 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.60632 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.62602 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.64572 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.66542 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.68512 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.70483 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.72453 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.74424 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.76395 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.78366 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.80337 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.82309 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.8428 seconds.             
Sun Jan 11 13:50:14 2015        Simulation at time: 7.86252 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.88224 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.90197 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.92169 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.94142 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.96115 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 7.98088 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 8.00062 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 8.02035 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 8.04009 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 8.05984 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 8.07958 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 8.09933 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 8.11908 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 8.13884 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 8.1586 seconds.             
Sun Jan 11 13:50:14 2015        Simulation at time: 8.17836 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 8.19813 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 8.2179 seconds.             
Sun Jan 11 13:50:14 2015        Simulation at time: 8.23767 seconds.            
Sun Jan 11 13:50:14 2015        Simulation at time: 8.25745 seconds.            
Sun Jan 11 13:50:14 2015        Writing output file at time: 8.25745 seconds    
Sun Jan 11 13:50:22 2015        Simulation at time: 8.27723 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.29701 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.3168 seconds.             
Sun Jan 11 13:50:22 2015        Simulation at time: 8.33659 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.35639 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.37619 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.396 seconds.              
Sun Jan 11 13:50:22 2015        Simulation at time: 8.41581 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.43563 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.45545 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.47528 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.49512 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.51495 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.5348 seconds.             
Sun Jan 11 13:50:22 2015        Simulation at time: 8.55465 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.5745 seconds.             
Sun Jan 11 13:50:22 2015        Simulation at time: 8.59437 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.61424 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.63411 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.654 seconds.              
Sun Jan 11 13:50:22 2015        Simulation at time: 8.67389 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.69378 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.71369 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.7336 seconds.             
Sun Jan 11 13:50:22 2015        Simulation at time: 8.75352 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.77345 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.79339 seconds.            
Sun Jan 11 13:50:22 2015        Simulation at time: 8.81334 seconds.            
Sun Jan 11 13:50:23 2015        Simulation at time: 8.83329 seconds.            
Sun Jan 11 13:50:23 2015        Simulation at time: 8.85326 seconds.            
Sun Jan 11 13:50:23 2015        Simulation at time: 8.87323 seconds.            
Sun Jan 11 13:50:23 2015        Simulation at time: 8.89322 seconds.            
Sun Jan 11 13:50:23 2015        Simulation at time: 8.91321 seconds.            
Sun Jan 11 13:50:23 2015        Simulation at time: 8.93322 seconds.            
Sun Jan 11 13:50:23 2015        Simulation at time: 8.95324 seconds.            
Sun Jan 11 13:50:23 2015        Simulation at time: 8.97327 seconds.            
Sun Jan 11 13:50:23 2015        Simulation at time: 8.99331 seconds.            
Sun Jan 11 13:50:23 2015        Simulation at time: 9.01336 seconds.            
Sun Jan 11 13:50:23 2015        Writing output file at time: 9.01336 seconds    
Sun Jan 11 13:50:30 2015        Simulation at time: 9.03343 seconds.            
Sun Jan 11 13:50:30 2015        Simulation at time: 9.05351 seconds.            
Sun Jan 11 13:50:30 2015        Simulation at time: 9.0736 seconds.             
Sun Jan 11 13:50:30 2015        Simulation at time: 9.09371 seconds.            
Sun Jan 11 13:50:30 2015        Simulation at time: 9.11383 seconds.            
Sun Jan 11 13:50:30 2015        Simulation at time: 9.13397 seconds.            
Sun Jan 11 13:50:30 2015        Simulation at time: 9.15413 seconds.            
Sun Jan 11 13:50:30 2015        Simulation at time: 9.1743 seconds.             
Sun Jan 11 13:50:30 2015        Simulation at time: 9.19449 seconds.            
Sun Jan 11 13:50:30 2015        Simulation at time: 9.21469 seconds.            
Sun Jan 11 13:50:30 2015        Simulation at time: 9.23492 seconds.            
Sun Jan 11 13:50:30 2015        Simulation at time: 9.25516 seconds.            
Sun Jan 11 13:50:30 2015        Simulation at time: 9.27543 seconds.            
Sun Jan 11 13:50:30 2015        Simulation at time: 9.29571 seconds.            
Sun Jan 11 13:50:30 2015        Simulation at time: 9.31602 seconds.            
Sun Jan 11 13:50:30 2015        Simulation at time: 9.33635 seconds.            
Sun Jan 11 13:50:30 2015        Simulation at time: 9.3567 seconds.             
Sun Jan 11 13:50:31 2015        Simulation at time: 9.37708 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.39748 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.41791 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.43836 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.45884 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.47935 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.49989 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.52046 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.54106 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.5617 seconds.             
Sun Jan 11 13:50:31 2015        Simulation at time: 9.58236 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.60306 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.6238 seconds.             
Sun Jan 11 13:50:31 2015        Simulation at time: 9.64457 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.66538 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.68623 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.70711 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.72804 seconds.            
Sun Jan 11 13:50:31 2015        Simulation at time: 9.749 seconds.              
Sun Jan 11 13:50:31 2015        Simulation at time: 9.77001 seconds.            
Sun Jan 11 13:50:31 2015        Writing output file at time: 9.77001 seconds    
Sun Jan 11 13:50:38 2015        Simulation at time: 9.79106 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 9.81215 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 9.83326 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 9.85439 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 9.87553 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 9.89668 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 9.91785 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 9.93903 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 9.96022 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 9.98142 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.0026 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.0239 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.0451 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.0664 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.0876 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.1089 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.1302 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.1515 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.1728 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.1941 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.2154 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.2367 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.258 seconds.             
Sun Jan 11 13:50:39 2015        Simulation at time: 10.2794 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.3007 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.322 seconds.             
Sun Jan 11 13:50:39 2015        Simulation at time: 10.3434 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.3647 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.3861 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.4074 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.4288 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.4501 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.4715 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.4929 seconds.            
Sun Jan 11 13:50:39 2015        Simulation at time: 10.5142 seconds.            
Sun Jan 11 13:50:39 2015        Writing output file at time: 10.5142 seconds    
Sun Jan 11 13:50:47 2015        Simulation at time: 10.5356 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.557 seconds.             
Sun Jan 11 13:50:47 2015        Simulation at time: 10.5783 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.5997 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.6211 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.6425 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.6639 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.6853 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.7067 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.7281 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.7495 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.7709 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.7923 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.8137 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.8351 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.8566 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.878 seconds.             
Sun Jan 11 13:50:47 2015        Simulation at time: 10.8994 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.9209 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.9423 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.9637 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 10.9852 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 11.0066 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 11.0281 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 11.0495 seconds.            
Sun Jan 11 13:50:47 2015        Simulation at time: 11.071 seconds.             
Sun Jan 11 13:50:48 2015        Simulation at time: 11.0924 seconds.            
Sun Jan 11 13:50:48 2015        Simulation at time: 11.1139 seconds.            
Sun Jan 11 13:50:48 2015        Simulation at time: 11.1353 seconds.            
Sun Jan 11 13:50:48 2015        Simulation at time: 11.1568 seconds.            
Sun Jan 11 13:50:48 2015        Simulation at time: 11.1783 seconds.            
Sun Jan 11 13:50:48 2015        Simulation at time: 11.1998 seconds.            
Sun Jan 11 13:50:48 2015        Simulation at time: 11.2212 seconds.            
Sun Jan 11 13:50:48 2015        Simulation at time: 11.2427 seconds.            
Sun Jan 11 13:50:48 2015        Simulation at time: 11.2642 seconds.            
Sun Jan 11 13:50:48 2015        Writing output file at time: 11.2642 seconds    
Sun Jan 11 13:50:55 2015        Simulation at time: 11.2857 seconds.            
Sun Jan 11 13:50:55 2015        Simulation at time: 11.3072 seconds.            
Sun Jan 11 13:50:55 2015        Simulation at time: 11.3287 seconds.            
Sun Jan 11 13:50:55 2015        Simulation at time: 11.3502 seconds.            
Sun Jan 11 13:50:55 2015        Simulation at time: 11.3717 seconds.            
Sun Jan 11 13:50:55 2015        Simulation at time: 11.3932 seconds.            
Sun Jan 11 13:50:55 2015        Simulation at time: 11.4147 seconds.            
Sun Jan 11 13:50:55 2015        Simulation at time: 11.4362 seconds.            
Sun Jan 11 13:50:55 2015        Simulation at time: 11.4577 seconds.            
Sun Jan 11 13:50:55 2015        Simulation at time: 11.4792 seconds.            
Sun Jan 11 13:50:55 2015        Simulation at time: 11.5007 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.5222 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.5438 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.5653 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.5868 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.6084 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.6299 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.6514 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.673 seconds.             
Sun Jan 11 13:50:56 2015        Simulation at time: 11.6945 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.7161 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.7376 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.7592 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.7807 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.8023 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.8238 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.8454 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.867 seconds.             
Sun Jan 11 13:50:56 2015        Simulation at time: 11.8885 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.9101 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.9317 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.9532 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.9748 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 11.9964 seconds.            
Sun Jan 11 13:50:56 2015        Simulation at time: 12.018 seconds.             
Sun Jan 11 13:50:56 2015        Writing output file at time: 12.018 seconds     
Sun Jan 11 13:51:03 2015        Simulation at time: 12.0396 seconds.            
Sun Jan 11 13:51:03 2015        Simulation at time: 12.0612 seconds.            
Sun Jan 11 13:51:03 2015        Simulation at time: 12.0827 seconds.            
Sun Jan 11 13:51:03 2015        Simulation at time: 12.1043 seconds.            
Sun Jan 11 13:51:03 2015        Simulation at time: 12.1259 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.1475 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.1691 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.1907 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.2124 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.234 seconds.             
Sun Jan 11 13:51:04 2015        Simulation at time: 12.2556 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.2772 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.2988 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.3204 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.342 seconds.             
Sun Jan 11 13:51:04 2015        Simulation at time: 12.3637 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.3853 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.4069 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.4286 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.4502 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.4718 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.4935 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.5151 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.5368 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.5584 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.5801 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.6017 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.6234 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.645 seconds.             
Sun Jan 11 13:51:04 2015        Simulation at time: 12.6667 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.6883 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.71 seconds.              
Sun Jan 11 13:51:04 2015        Simulation at time: 12.7317 seconds.            
Sun Jan 11 13:51:04 2015        Simulation at time: 12.7533 seconds.            
Sun Jan 11 13:51:04 2015        Writing output file at time: 12.7533 seconds    
Sun Jan 11 13:51:12 2015        Simulation at time: 12.775 seconds.             
Sun Jan 11 13:51:12 2015        Simulation at time: 12.7967 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 12.8184 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 12.8401 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 12.8617 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 12.8834 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 12.9051 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 12.9268 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 12.9485 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 12.9702 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 12.9919 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.0136 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.0353 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.057 seconds.             
Sun Jan 11 13:51:12 2015        Simulation at time: 13.0787 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.1004 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.1221 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.1438 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.1655 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.1872 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.2089 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.2307 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.2524 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.2741 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.2958 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.3176 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.3393 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.361 seconds.             
Sun Jan 11 13:51:12 2015        Simulation at time: 13.3828 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.4045 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.4262 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.448 seconds.             
Sun Jan 11 13:51:12 2015        Simulation at time: 13.4697 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.4915 seconds.            
Sun Jan 11 13:51:12 2015        Simulation at time: 13.5132 seconds.            
Sun Jan 11 13:51:12 2015        Writing output file at time: 13.5132 seconds    
Sun Jan 11 13:51:20 2015        Simulation at time: 13.535 seconds.             
Sun Jan 11 13:51:20 2015        Simulation at time: 13.5567 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.5785 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.6002 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.622 seconds.             
Sun Jan 11 13:51:20 2015        Simulation at time: 13.6437 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.6655 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.6873 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.709 seconds.             
Sun Jan 11 13:51:20 2015        Simulation at time: 13.7308 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.7526 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.7743 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.7961 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.8179 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.8396 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.8614 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.8832 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.905 seconds.             
Sun Jan 11 13:51:20 2015        Simulation at time: 13.9268 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.9486 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.9704 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 13.9921 seconds.            
Sun Jan 11 13:51:20 2015        Simulation at time: 14.0139 seconds.            
Sun Jan 11 13:51:21 2015        Simulation at time: 14.0357 seconds.            
Sun Jan 11 13:51:21 2015        Simulation at time: 14.0575 seconds.            
Sun Jan 11 13:51:21 2015        Simulation at time: 14.0793 seconds.            
Sun Jan 11 13:51:21 2015        Simulation at time: 14.1011 seconds.            
Sun Jan 11 13:51:21 2015        Simulation at time: 14.1229 seconds.            
Sun Jan 11 13:51:21 2015        Simulation at time: 14.1447 seconds.            
Sun Jan 11 13:51:21 2015        Simulation at time: 14.1665 seconds.            
Sun Jan 11 13:51:21 2015        Simulation at time: 14.1884 seconds.            
Sun Jan 11 13:51:21 2015        Simulation at time: 14.2102 seconds.            
Sun Jan 11 13:51:21 2015        Simulation at time: 14.232 seconds.             
Sun Jan 11 13:51:21 2015        Simulation at time: 14.2538 seconds.            
Sun Jan 11 13:51:21 2015        Writing output file at time: 14.2538 seconds    
Sun Jan 11 13:51:28 2015        Simulation at time: 14.2756 seconds.            
Sun Jan 11 13:51:28 2015        Simulation at time: 14.2974 seconds.            
Sun Jan 11 13:51:28 2015        Simulation at time: 14.3193 seconds.            
Sun Jan 11 13:51:28 2015        Simulation at time: 14.3411 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.3629 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.3847 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.4066 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.4284 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.4502 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.4721 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.4939 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.5157 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.5376 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.5594 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.5813 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.6031 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.625 seconds.             
Sun Jan 11 13:51:29 2015        Simulation at time: 14.6468 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.6687 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.6905 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.7124 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.7342 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.7561 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.7779 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.7998 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.8217 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.8435 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.8654 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.8873 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.9092 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.931 seconds.             
Sun Jan 11 13:51:29 2015        Simulation at time: 14.9529 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.9748 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 14.9967 seconds.            
Sun Jan 11 13:51:29 2015        Simulation at time: 15.0186 seconds.            
Sun Jan 11 13:51:29 2015        Writing output file at time: 15.0186 seconds    
                                                                                
------------------------------------------------------------------
Sun Jan 11 13:51:37 2015	Simulation finished. Printing statistics for each process.
------------------------------------------------------------------
Sun Jan 11 13:51:37 2015	process 0 - CPU time: 146.21 seconds
Sun Jan 11 13:51:37 2015	process 0 - wall clock time: 167 seconds
Sun Jan 11 13:51:37 2015	733 iterations done

*************************************************************
SWE finished successfully.
*************************************************************

real	2m56.493s
user	3m40.190s
sys	2m37.750s

*************************************************************
Welcome to SWE

SWE Copyright (C) 2012-2013
  Technische Universitaet Muenchen
  Department of Informatics
  Chair of Scientific Computing
  http://www5.in.tum.de/SWE

SWE comes with ABSOLUTELY NO WARRANTY.
SWE is free software, and you are welcome to redistribute it
under certain conditions.
Details can be found in the file 'gpl.txt'.
*************************************************************
Sun Jan 11 13:51:37 2015	Writing output file at time: 0 seconds
                                                                                
------------------------------------------------------------------
Sun Jan 11 13:51:47 2015	Everything is set up, starting the simulation.
------------------------------------------------------------------
Sun Jan 11 13:51:47 2015        Simulation at time: 0.0219831 seconds.          
Sun Jan 11 13:51:47 2015        Simulation at time: 0.0432806 seconds.          
Sun Jan 11 13:51:47 2015        Simulation at time: 0.0642069 seconds.          
Sun Jan 11 13:51:47 2015        Simulation at time: 0.0848982 seconds.          
Sun Jan 11 13:51:47 2015        Simulation at time: 0.105438 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.125793 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.146023 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.166186 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.186302 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.206399 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.226492 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.246591 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.266673 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.286752 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.306841 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.326948 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.347074 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.367217 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.387362 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.407508 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.427655 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.447803 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.467952 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.488099 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.508247 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.528394 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.548542 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.568689 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.588834 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.608978 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.629122 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.649266 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.669409 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.68955 seconds.            
Sun Jan 11 13:51:47 2015        Simulation at time: 0.70969 seconds.            
Sun Jan 11 13:51:47 2015        Simulation at time: 0.729831 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.749971 seconds.           
Sun Jan 11 13:51:47 2015        Simulation at time: 0.770112 seconds.           
Sun Jan 11 13:51:47 2015        Writing output file at time: 0.770112 seconds   
Sun Jan 11 13:51:55 2015        Simulation at time: 0.790251 seconds.           
Sun Jan 11 13:51:55 2015        Simulation at time: 0.810388 seconds.           
Sun Jan 11 13:51:55 2015        Simulation at time: 0.830525 seconds.           
Sun Jan 11 13:51:55 2015        Simulation at time: 0.850662 seconds.           
Sun Jan 11 13:51:55 2015        Simulation at time: 0.870797 seconds.           
Sun Jan 11 13:51:55 2015        Simulation at time: 0.890927 seconds.           
Sun Jan 11 13:51:55 2015        Simulation at time: 0.911055 seconds.           
Sun Jan 11 13:51:55 2015        Simulation at time: 0.931181 seconds.           
Sun Jan 11 13:51:55 2015        Simulation at time: 0.951306 seconds.           
Sun Jan 11 13:51:55 2015        Simulation at time: 0.971428 seconds.           
Sun Jan 11 13:51:55 2015        Simulation at time: 0.991548 seconds.           
Sun Jan 11 13:51:55 2015        Simulation at time: 1.01167 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.03178 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.0519 seconds.             
Sun Jan 11 13:51:55 2015        Simulation at time: 1.07201 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.09212 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.11223 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.13234 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.15245 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.17256 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.19267 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.21277 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.23288 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.25298 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.27309 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.29319 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.31329 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.33339 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.35349 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.37359 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.39368 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.41378 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.43387 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.45397 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.47406 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.49415 seconds.            
Sun Jan 11 13:51:55 2015        Simulation at time: 1.51424 seconds.            
Sun Jan 11 13:51:55 2015        Writing output file at time: 1.51424 seconds    
Sun Jan 11 13:52:03 2015        Simulation at time: 1.53432 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.55441 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.5745 seconds.             
Sun Jan 11 13:52:03 2015        Simulation at time: 1.59458 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.61466 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.63474 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.65482 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.6749 seconds.             
Sun Jan 11 13:52:03 2015        Simulation at time: 1.69497 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.71505 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.73512 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.75519 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.77526 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.79533 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.8154 seconds.             
Sun Jan 11 13:52:03 2015        Simulation at time: 1.83546 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.85553 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.87559 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.89565 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.91571 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.93577 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.95582 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.97588 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 1.99593 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 2.01598 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 2.03603 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 2.05608 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 2.07613 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 2.09617 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 2.11622 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 2.13626 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 2.1563 seconds.             
Sun Jan 11 13:52:03 2015        Simulation at time: 2.17634 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 2.19637 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 2.21641 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 2.23644 seconds.            
Sun Jan 11 13:52:03 2015        Simulation at time: 2.25647 seconds.            
Sun Jan 11 13:52:03 2015        Writing output file at time: 2.25647 seconds    
Sun Jan 11 13:52:11 2015        Simulation at time: 2.2765 seconds.             
Sun Jan 11 13:52:11 2015        Simulation at time: 2.29653 seconds.            
Sun Jan 11 13:52:11 2015        Simulation at time: 2.31656 seconds.            
Sun Jan 11 13:52:11 2015        Simulation at time: 2.33658 seconds.            
Sun Jan 11 13:52:11 2015        Simulation at time: 2.35661 seconds.            
Sun Jan 11 13:52:11 2015        Simulation at time: 2.37663 seconds.            
Sun Jan 11 13:52:11 2015        Simulation at time: 2.39665 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.41667 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.43668 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.4567 seconds.             
Sun Jan 11 13:52:12 2015        Simulation at time: 2.47671 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.49672 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.51673 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.53674 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.55675 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.57675 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.59676 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.61676 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.63676 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.65676 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.67675 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.69675 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.71674 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.73674 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.75673 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.77671 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.7967 seconds.             
Sun Jan 11 13:52:12 2015        Simulation at time: 2.81669 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.83667 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.85665 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.87663 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.89661 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.91659 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.93656 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.95654 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.97651 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 2.99648 seconds.            
Sun Jan 11 13:52:12 2015        Simulation at time: 3.01645 seconds.            
Sun Jan 11 13:52:12 2015        Writing output file at time: 3.01645 seconds    
Sun Jan 11 13:52:20 2015        Simulation at time: 3.03642 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.05638 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.07634 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.09631 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.11627 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.13623 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.15618 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.17614 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.19609 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.21604 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.236 seconds.              
Sun Jan 11 13:52:20 2015        Simulation at time: 3.25594 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.27589 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.29584 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.31578 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.33572 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.35566 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.3756 seconds.             
Sun Jan 11 13:52:20 2015        Simulation at time: 3.39554 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.41547 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.43541 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.45534 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.47527 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.49519 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.51512 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.53505 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.55497 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.57489 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.59481 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.61473 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.63464 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.65456 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.67447 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.69438 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.71429 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.73419 seconds.            
Sun Jan 11 13:52:20 2015        Simulation at time: 3.7541 seconds.             
Sun Jan 11 13:52:20 2015        Writing output file at time: 3.7541 seconds     
Sun Jan 11 13:52:28 2015        Simulation at time: 3.774 seconds.              
Sun Jan 11 13:52:28 2015        Simulation at time: 3.7939 seconds.             
Sun Jan 11 13:52:28 2015        Simulation at time: 3.8138 seconds.             
Sun Jan 11 13:52:28 2015        Simulation at time: 3.8337 seconds.             
Sun Jan 11 13:52:28 2015        Simulation at time: 3.85359 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 3.87349 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 3.89338 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 3.91327 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 3.93316 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 3.95304 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 3.97293 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 3.99281 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.01269 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.03257 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.05245 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.07232 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.0922 seconds.             
Sun Jan 11 13:52:28 2015        Simulation at time: 4.11207 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.13194 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.1518 seconds.             
Sun Jan 11 13:52:28 2015        Simulation at time: 4.17167 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.19153 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.21139 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.23125 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.25111 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.27097 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.29082 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.31067 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.33053 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.35037 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.37022 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.39006 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.40991 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.42975 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.44959 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.46943 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.48926 seconds.            
Sun Jan 11 13:52:28 2015        Simulation at time: 4.50909 seconds.            
Sun Jan 11 13:52:28 2015        Writing output file at time: 4.50909 seconds    
Sun Jan 11 13:52:36 2015        Simulation at time: 4.52893 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.54876 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.56858 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.58841 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.60823 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.62806 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.64788 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.6677 seconds.             
Sun Jan 11 13:52:36 2015        Simulation at time: 4.68751 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.70733 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.72714 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.74695 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.76676 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.78657 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.80638 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.82618 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.84598 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.86578 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.88558 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.90538 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.92517 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.94497 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.96476 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 4.98455 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 5.00434 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 5.02412 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 5.04391 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 5.06369 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 5.08348 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 5.10325 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 5.12303 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 5.14281 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 5.16259 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 5.18236 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 5.20213 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 5.2219 seconds.             
Sun Jan 11 13:52:36 2015        Simulation at time: 5.24167 seconds.            
Sun Jan 11 13:52:36 2015        Simulation at time: 5.26144 seconds.            
Sun Jan 11 13:52:36 2015        Writing output file at time: 5.26144 seconds    
Sun Jan 11 13:52:44 2015        Simulation at time: 5.2812 seconds.             
Sun Jan 11 13:52:44 2015        Simulation at time: 5.30097 seconds.            
Sun Jan 11 13:52:44 2015        Simulation at time: 5.32073 seconds.            
Sun Jan 11 13:52:44 2015        Simulation at time: 5.34049 seconds.            
Sun Jan 11 13:52:44 2015        Simulation at time: 5.36025 seconds.            
Sun Jan 11 13:52:44 2015        Simulation at time: 5.38001 seconds.            
Sun Jan 11 13:52:44 2015        Simulation at time: 5.39976 seconds.            
Sun Jan 11 13:52:44 2015        Simulation at time: 5.41952 seconds.            
Sun Jan 11 13:52:44 2015        Simulation at time: 5.43927 seconds.            
Sun Jan 11 13:52:44 2015        Simulation at time: 5.45902 seconds.            
Sun Jan 11 13:52:44 2015        Simulation at time: 5.47877 seconds.            
Sun Jan 11 13:52:44 2015        Simulation at time: 5.49852 seconds.            
Sun Jan 11 13:52:44 2015        Simulation at time: 5.51827 seconds.            
Sun Jan 11 13:52:44 2015        Simulation at time: 5.53801 seconds.            
Sun Jan 11 13:52:44 2015        Simulation at time: 5.55775 seconds.            
Sun Jan 11 13:52:44 2015        Simulation at time: 5.5775 seconds.             
Sun Jan 11 13:52:44 2015        Simulation at time: 5.59724 seconds.            
Sun Jan 11 13:52:44 2015        Simulation at time: 5.61698 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.63672 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.65645 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.67619 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.69592 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.71566 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.73539 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.75512 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.77485 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.79458 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.8143 seconds.             
Sun Jan 11 13:52:45 2015        Simulation at time: 5.83403 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.85375 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.87347 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.89319 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.91291 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.93263 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.95235 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.97207 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 5.99178 seconds.            
Sun Jan 11 13:52:45 2015        Simulation at time: 6.01149 seconds.            
Sun Jan 11 13:52:45 2015        Writing output file at time: 6.01149 seconds    
Sun Jan 11 13:52:52 2015        Simulation at time: 6.03121 seconds.            
Sun Jan 11 13:52:52 2015        Simulation at time: 6.05092 seconds.            
Sun Jan 11 13:52:52 2015        Simulation at time: 6.07063 seconds.            
Sun Jan 11 13:52:52 2015        Simulation at time: 6.09034 seconds.            
Sun Jan 11 13:52:52 2015        Simulation at time: 6.11005 seconds.            
Sun Jan 11 13:52:52 2015        Simulation at time: 6.12975 seconds.            
Sun Jan 11 13:52:52 2015        Simulation at time: 6.14946 seconds.            
Sun Jan 11 13:52:52 2015        Simulation at time: 6.16916 seconds.            
Sun Jan 11 13:52:52 2015        Simulation at time: 6.18887 seconds.            
Sun Jan 11 13:52:52 2015        Simulation at time: 6.20857 seconds.            
Sun Jan 11 13:52:52 2015        Simulation at time: 6.22827 seconds.            
Sun Jan 11 13:52:52 2015        Simulation at time: 6.24797 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.26767 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.28737 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.30707 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.32677 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.34646 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.36616 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.38585 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.40555 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.42524 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.44493 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.46462 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.48431 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.504 seconds.              
Sun Jan 11 13:52:53 2015        Simulation at time: 6.52369 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.54338 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.56307 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.58276 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.60244 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.62213 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.64181 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.6615 seconds.             
Sun Jan 11 13:52:53 2015        Simulation at time: 6.68118 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.70087 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.72055 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.74023 seconds.            
Sun Jan 11 13:52:53 2015        Simulation at time: 6.75991 seconds.            
Sun Jan 11 13:52:53 2015        Writing output file at time: 6.75991 seconds    
Sun Jan 11 13:53:00 2015        Simulation at time: 6.7796 seconds.             
Sun Jan 11 13:53:00 2015        Simulation at time: 6.79928 seconds.            
Sun Jan 11 13:53:00 2015        Simulation at time: 6.81896 seconds.            
Sun Jan 11 13:53:00 2015        Simulation at time: 6.83864 seconds.            
Sun Jan 11 13:53:00 2015        Simulation at time: 6.85832 seconds.            
Sun Jan 11 13:53:00 2015        Simulation at time: 6.878 seconds.              
Sun Jan 11 13:53:00 2015        Simulation at time: 6.89768 seconds.            
Sun Jan 11 13:53:00 2015        Simulation at time: 6.91736 seconds.            
Sun Jan 11 13:53:00 2015        Simulation at time: 6.93704 seconds.            
Sun Jan 11 13:53:00 2015        Simulation at time: 6.95672 seconds.            
Sun Jan 11 13:53:00 2015        Simulation at time: 6.9764 seconds.             
Sun Jan 11 13:53:00 2015        Simulation at time: 6.99608 seconds.            
Sun Jan 11 13:53:00 2015        Simulation at time: 7.01576 seconds.            
Sun Jan 11 13:53:00 2015        Simulation at time: 7.03544 seconds.            
Sun Jan 11 13:53:00 2015        Simulation at time: 7.05512 seconds.            
Sun Jan 11 13:53:00 2015        Simulation at time: 7.0748 seconds.             
Sun Jan 11 13:53:01 2015        Simulation at time: 7.09448 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.11416 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.13384 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.15352 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.1732 seconds.             
Sun Jan 11 13:53:01 2015        Simulation at time: 7.19288 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.21256 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.23225 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.25193 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.27161 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.29129 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.31098 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.33066 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.35035 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.37003 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.38972 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.4094 seconds.             
Sun Jan 11 13:53:01 2015        Simulation at time: 7.42909 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.44878 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.46847 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.48816 seconds.            
Sun Jan 11 13:53:01 2015        Simulation at time: 7.50785 seconds.            
Sun Jan 11 13:53:01 2015        Writing output file at time: 7.50785 seconds    
Sun Jan 11 13:53:09 2015        Simulation at time: 7.52754 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.54724 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.56693 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.58663 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.60632 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.62602 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.64572 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.66542 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.68512 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.70483 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.72453 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.74424 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.76395 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.78366 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.80337 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.82309 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.8428 seconds.             
Sun Jan 11 13:53:09 2015        Simulation at time: 7.86252 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.88224 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.90197 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.92169 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.94142 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.96115 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 7.98088 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 8.00062 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 8.02035 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 8.04009 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 8.05984 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 8.07958 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 8.09933 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 8.11908 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 8.13884 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 8.1586 seconds.             
Sun Jan 11 13:53:09 2015        Simulation at time: 8.17836 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 8.19813 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 8.2179 seconds.             
Sun Jan 11 13:53:09 2015        Simulation at time: 8.23767 seconds.            
Sun Jan 11 13:53:09 2015        Simulation at time: 8.25745 seconds.            
Sun Jan 11 13:53:09 2015        Writing output file at time: 8.25745 seconds    
Sun Jan 11 13:53:17 2015        Simulation at time: 8.27723 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.29701 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.3168 seconds.             
Sun Jan 11 13:53:17 2015        Simulation at time: 8.33659 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.35639 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.37619 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.396 seconds.              
Sun Jan 11 13:53:17 2015        Simulation at time: 8.41581 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.43563 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.45545 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.47528 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.49512 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.51495 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.5348 seconds.             
Sun Jan 11 13:53:17 2015        Simulation at time: 8.55465 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.5745 seconds.             
Sun Jan 11 13:53:17 2015        Simulation at time: 8.59437 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.61424 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.63411 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.654 seconds.              
Sun Jan 11 13:53:17 2015        Simulation at time: 8.67389 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.69378 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.71369 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.7336 seconds.             
Sun Jan 11 13:53:17 2015        Simulation at time: 8.75352 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.77345 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.79339 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.81334 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.83329 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.85326 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.87323 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.89322 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.91321 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.93322 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.95324 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.97327 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 8.99331 seconds.            
Sun Jan 11 13:53:17 2015        Simulation at time: 9.01336 seconds.            
Sun Jan 11 13:53:17 2015        Writing output file at time: 9.01336 seconds    
Sun Jan 11 13:53:25 2015        Simulation at time: 9.03343 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.05351 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.0736 seconds.             
Sun Jan 11 13:53:25 2015        Simulation at time: 9.09371 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.11383 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.13397 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.15413 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.1743 seconds.             
Sun Jan 11 13:53:25 2015        Simulation at time: 9.19449 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.21469 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.23492 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.25516 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.27543 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.29571 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.31602 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.33635 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.3567 seconds.             
Sun Jan 11 13:53:25 2015        Simulation at time: 9.37708 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.39748 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.41791 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.43836 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.45884 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.47935 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.49989 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.52046 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.54106 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.5617 seconds.             
Sun Jan 11 13:53:25 2015        Simulation at time: 9.58236 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.60306 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.6238 seconds.             
Sun Jan 11 13:53:25 2015        Simulation at time: 9.64457 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.66538 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.68623 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.70711 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.72804 seconds.            
Sun Jan 11 13:53:25 2015        Simulation at time: 9.749 seconds.              
Sun Jan 11 13:53:25 2015        Simulation at time: 9.77001 seconds.            
Sun Jan 11 13:53:25 2015        Writing output file at time: 9.77001 seconds    
Sun Jan 11 13:53:33 2015        Simulation at time: 9.79106 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 9.81215 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 9.83326 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 9.85439 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 9.87553 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 9.89668 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 9.91785 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 9.93903 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 9.96022 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 9.98142 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.0026 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.0239 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.0451 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.0664 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.0876 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.1089 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.1302 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.1515 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.1728 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.1941 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.2154 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.2367 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.258 seconds.             
Sun Jan 11 13:53:33 2015        Simulation at time: 10.2794 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.3007 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.322 seconds.             
Sun Jan 11 13:53:33 2015        Simulation at time: 10.3434 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.3647 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.3861 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.4074 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.4288 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.4501 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.4715 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.4929 seconds.            
Sun Jan 11 13:53:33 2015        Simulation at time: 10.5142 seconds.            
Sun Jan 11 13:53:33 2015        Writing output file at time: 10.5142 seconds    
Sun Jan 11 13:53:41 2015        Simulation at time: 10.5356 seconds.            
Sun Jan 11 13:53:41 2015        Simulation at time: 10.557 seconds.             
Sun Jan 11 13:53:41 2015        Simulation at time: 10.5783 seconds.            
Sun Jan 11 13:53:41 2015        Simulation at time: 10.5997 seconds.            
Sun Jan 11 13:53:41 2015        Simulation at time: 10.6211 seconds.            
Sun Jan 11 13:53:41 2015        Simulation at time: 10.6425 seconds.            
Sun Jan 11 13:53:41 2015        Simulation at time: 10.6639 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 10.6853 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 10.7067 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 10.7281 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 10.7495 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 10.7709 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 10.7923 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 10.8137 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 10.8351 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 10.8566 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 10.878 seconds.             
Sun Jan 11 13:53:42 2015        Simulation at time: 10.8994 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 10.9209 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 10.9423 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 10.9637 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 10.9852 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 11.0066 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 11.0281 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 11.0495 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 11.071 seconds.             
Sun Jan 11 13:53:42 2015        Simulation at time: 11.0924 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 11.1139 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 11.1353 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 11.1568 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 11.1783 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 11.1998 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 11.2212 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 11.2427 seconds.            
Sun Jan 11 13:53:42 2015        Simulation at time: 11.2642 seconds.            
Sun Jan 11 13:53:42 2015        Writing output file at time: 11.2642 seconds    
Sun Jan 11 13:53:49 2015        Simulation at time: 11.2857 seconds.            
Sun Jan 11 13:53:49 2015        Simulation at time: 11.3072 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.3287 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.3502 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.3717 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.3932 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.4147 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.4362 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.4577 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.4792 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.5007 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.5222 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.5438 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.5653 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.5868 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.6084 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.6299 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.6514 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.673 seconds.             
Sun Jan 11 13:53:50 2015        Simulation at time: 11.6945 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.7161 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.7376 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.7592 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.7807 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.8023 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.8238 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.8454 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.867 seconds.             
Sun Jan 11 13:53:50 2015        Simulation at time: 11.8885 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.9101 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.9317 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.9532 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.9748 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 11.9964 seconds.            
Sun Jan 11 13:53:50 2015        Simulation at time: 12.018 seconds.             
Sun Jan 11 13:53:50 2015        Writing output file at time: 12.018 seconds     
Sun Jan 11 13:53:57 2015        Simulation at time: 12.0396 seconds.            
Sun Jan 11 13:53:57 2015        Simulation at time: 12.0612 seconds.            
Sun Jan 11 13:53:57 2015        Simulation at time: 12.0827 seconds.            
Sun Jan 11 13:53:57 2015        Simulation at time: 12.1043 seconds.            
Sun Jan 11 13:53:57 2015        Simulation at time: 12.1259 seconds.            
Sun Jan 11 13:53:57 2015        Simulation at time: 12.1475 seconds.            
Sun Jan 11 13:53:57 2015        Simulation at time: 12.1691 seconds.            
Sun Jan 11 13:53:57 2015        Simulation at time: 12.1907 seconds.            
Sun Jan 11 13:53:57 2015        Simulation at time: 12.2124 seconds.            
Sun Jan 11 13:53:57 2015        Simulation at time: 12.234 seconds.             
Sun Jan 11 13:53:57 2015        Simulation at time: 12.2556 seconds.            
Sun Jan 11 13:53:57 2015        Simulation at time: 12.2772 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.2988 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.3204 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.342 seconds.             
Sun Jan 11 13:53:58 2015        Simulation at time: 12.3637 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.3853 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.4069 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.4286 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.4502 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.4718 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.4935 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.5151 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.5368 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.5584 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.5801 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.6017 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.6234 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.645 seconds.             
Sun Jan 11 13:53:58 2015        Simulation at time: 12.6667 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.6883 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.71 seconds.              
Sun Jan 11 13:53:58 2015        Simulation at time: 12.7317 seconds.            
Sun Jan 11 13:53:58 2015        Simulation at time: 12.7533 seconds.            
Sun Jan 11 13:53:58 2015        Writing output file at time: 12.7533 seconds    
Sun Jan 11 13:54:05 2015        Simulation at time: 12.775 seconds.             
Sun Jan 11 13:54:05 2015        Simulation at time: 12.7967 seconds.            
Sun Jan 11 13:54:05 2015        Simulation at time: 12.8184 seconds.            
Sun Jan 11 13:54:05 2015        Simulation at time: 12.8401 seconds.            
Sun Jan 11 13:54:05 2015        Simulation at time: 12.8617 seconds.            
Sun Jan 11 13:54:05 2015        Simulation at time: 12.8834 seconds.            
Sun Jan 11 13:54:05 2015        Simulation at time: 12.9051 seconds.            
Sun Jan 11 13:54:05 2015        Simulation at time: 12.9268 seconds.            
Sun Jan 11 13:54:05 2015        Simulation at time: 12.9485 seconds.            
Sun Jan 11 13:54:05 2015        Simulation at time: 12.9702 seconds.            
Sun Jan 11 13:54:05 2015        Simulation at time: 12.9919 seconds.            
Sun Jan 11 13:54:05 2015        Simulation at time: 13.0136 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.0353 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.057 seconds.             
Sun Jan 11 13:54:06 2015        Simulation at time: 13.0787 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.1004 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.1221 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.1438 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.1655 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.1872 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.2089 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.2307 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.2524 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.2741 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.2958 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.3176 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.3393 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.361 seconds.             
Sun Jan 11 13:54:06 2015        Simulation at time: 13.3828 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.4045 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.4262 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.448 seconds.             
Sun Jan 11 13:54:06 2015        Simulation at time: 13.4697 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.4915 seconds.            
Sun Jan 11 13:54:06 2015        Simulation at time: 13.5132 seconds.            
Sun Jan 11 13:54:06 2015        Writing output file at time: 13.5132 seconds    
Sun Jan 11 13:54:14 2015        Simulation at time: 13.535 seconds.             
Sun Jan 11 13:54:14 2015        Simulation at time: 13.5567 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.5785 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.6002 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.622 seconds.             
Sun Jan 11 13:54:14 2015        Simulation at time: 13.6437 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.6655 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.6873 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.709 seconds.             
Sun Jan 11 13:54:14 2015        Simulation at time: 13.7308 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.7526 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.7743 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.7961 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.8179 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.8396 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.8614 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.8832 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.905 seconds.             
Sun Jan 11 13:54:14 2015        Simulation at time: 13.9268 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.9486 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.9704 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 13.9921 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 14.0139 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 14.0357 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 14.0575 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 14.0793 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 14.1011 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 14.1229 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 14.1447 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 14.1665 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 14.1884 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 14.2102 seconds.            
Sun Jan 11 13:54:14 2015        Simulation at time: 14.232 seconds.             
Sun Jan 11 13:54:14 2015        Simulation at time: 14.2538 seconds.            
Sun Jan 11 13:54:14 2015        Writing output file at time: 14.2538 seconds    
Sun Jan 11 13:54:22 2015        Simulation at time: 14.2756 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.2974 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.3193 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.3411 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.3629 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.3847 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.4066 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.4284 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.4502 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.4721 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.4939 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.5157 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.5376 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.5594 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.5813 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.6031 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.625 seconds.             
Sun Jan 11 13:54:22 2015        Simulation at time: 14.6468 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.6687 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.6905 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.7124 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.7342 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.7561 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.7779 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.7998 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.8217 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.8435 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.8654 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.8873 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.9092 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.931 seconds.             
Sun Jan 11 13:54:22 2015        Simulation at time: 14.9529 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.9748 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 14.9967 seconds.            
Sun Jan 11 13:54:22 2015        Simulation at time: 15.0186 seconds.            
Sun Jan 11 13:54:22 2015        Writing output file at time: 15.0186 seconds    
                                                                                
------------------------------------------------------------------
Sun Jan 11 13:54:30 2015	Simulation finished. Printing statistics for each process.
------------------------------------------------------------------
Sun Jan 11 13:54:30 2015	process 0 - CPU time: 147.7 seconds
Sun Jan 11 13:54:30 2015	process 0 - wall clock time: 163 seconds
Sun Jan 11 13:54:30 2015	733 iterations done

*************************************************************
SWE finished successfully.
*************************************************************

real	2m53.145s
user	3m52.979s
sys	2m37.042s
t1221an@mac-snb16:~/swe-meas> 
