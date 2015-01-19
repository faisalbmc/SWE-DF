/**
 * @file
 * This file is part of SWE.
 *
 * @author Alexander Breuer (breuera AT in.tum.de, http://www5.in.tum.de/wiki/index.php/Dipl.-Math._Alexander_Breuer)
 *         Michael Bader (bader AT in.tum.de, http://www5.in.tum.de/wiki/index.php/Univ.-Prof._Dr._Michael_Bader)
 *
 * @section LICENSE
 *
 * SWE is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SWE is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SWE.  If not, see <http://www.gnu.org/licenses/>.
 *
 *
 * @section DESCRIPTION
 *
 * Basic setting of SWE, which uses a wave propagation solver and an artificial or ASAGI scenario on a single block.
 */

#include <cassert>
#include <cstdlib>
#include <string>
#include <iostream>
#include <time.h>
#include <sys/time.h>

/**
 * This is a modification to support the different blocks used in the project
 * In order to use another block, more modifications below must be done
 */

#if BLOCK_MODE==1
#include "../blocks/SWE_WavePropagationBlock.hh"
#elif BLOCK_MODE==2
#include "../blocks/SWE_WaveAccumulationBlock.hh"
#elif BLOCK_MODE==3
#include "../blocks/SWE_WaveAccumulationBlockIntrinsicTest.hh"
#elif BLOCK_MODE==4
#include "../blocks/SWE_WaveAccumulationBlockIntrinsic.hh"
#elif BLOCK_MODE==5
#include "../blocks/SWE_MICWaveAccumulationBlockIntrinsic.hh"
#endif


#ifdef WRITENETCDF
#include "writer/NetCdfWriter.hh"
#else
#include "writer/VtkWriter.hh"
#endif

#ifdef ASAGI
#include "scenarios/SWE_AsagiScenario.hh"
#else
#include "scenarios/SWE_simple_scenarios.hh"
#endif

#ifdef READXML
#include "tools/CXMLConfig.hpp"
#endif

#include "tools/args.hh"
#include "tools/help.hh"
#include "tools/Logger.hh"
#include "tools/ProgressBar.hh"

typedef struct {
	/** used by gettimeofday() */
	struct timeval tv;
	/** used by clock()  */
	clock_t ticks;
} time_marker_t;

time_marker_t get_time() {
  	time_marker_t retval;
  	gettimeofday(&retval.tv, NULL);
  	retval.ticks = clock();
  	return retval;
  }


  double get_ToD_diff_time(time_marker_t time) {
  	struct timeval tmp;
  	gettimeofday(&tmp, NULL);
  	tmp.tv_sec -= time.tv.tv_sec;
  	tmp.tv_usec -= time.tv.tv_usec;
  	return (double)tmp.tv_sec + (double)tmp.tv_usec*1e-6;
  }


  double get_ticks_diff_time(time_marker_t time) {
  	clock_t tmp = clock();
  	return ((tmp - time.ticks) / ((double)CLOCKS_PER_SEC));
  }

  void print_flops(int flop, time_marker_t time) {
  	printf("FLOPS with clock(): %e \n", (double) flop / (get_ticks_diff_time(time)));
  	printf("FLOPS with timeofday(): %e \n", (double) flop / (get_ToD_diff_time(time)));
  }


/**
 * Main program for the simulation on a single SWE_WavePropagationBlock.
 */
int main( int argc, char** argv ) {
  /**
   * Initialization.
   */
  // Parse command line parameters
  tools::Args args;
  #ifndef READXML
  args.addOption("grid-size-x", 'x', "Number of cells in x direction");
  args.addOption("grid-size-y", 'y', "Number of cells in y direction");
  args.addOption("output-basepath", 'o', "Output base file name");
  #endif

  tools::Args::Result ret = args.parse(argc, argv);

  switch (ret)
  {
  case tools::Args::Error:
	  return 1;
  case tools::Args::Help:
	  return 0;
  }

  //! number of grid cells in x- and y-direction.
  int l_nX, l_nY;

  //! l_baseName of the plots.
  std::string l_baseName;

  // read command line parameters
  #ifndef READXML
  l_nX = args.getArgument<int>("grid-size-x");
  l_nY = args.getArgument<int>("grid-size-y");
  l_baseName = args.getArgument<std::string>("output-basepath");
  #endif

  // read xml file
  #ifdef READXML
  assert(false); //TODO: not implemented.
  if(argc != 2) {
    s_sweLogger.printString("Aborting. Please provide a proper input file.");
    s_sweLogger.printString("Example: ./SWE_gnu_debug_none_augrie config.xml");
    return 1;
  }
  s_sweLogger.printString("Reading xml-file.");

  std::string l_xmlFile = std::string(argv[1]);
  s_sweLogger.printString(l_xmlFile);

  CXMLConfig l_xmlConfig;
  l_xmlConfig.loadConfig(l_xmlFile.c_str());
  #endif

  #ifdef ASAGI
  /* Information about the example bathymetry grid (tohoku_gebco_ucsb3_500m_hawaii_bath.nc):
   *
   * Pixel node registration used [Cartesian grid]
   * Grid file format: nf = GMT netCDF format (float)  (COARDS-compliant)
   * x_min: -500000 x_max: 6500000 x_inc: 500 name: x nx: 14000
   * y_min: -2500000 y_max: 1500000 y_inc: 500 name: y ny: 8000
   * z_min: -6.48760175705 z_max: 16.1780223846 name: z
   * scale_factor: 1 add_offset: 0
   * mean: 0.00217145586762 stdev: 0.245563641735 rms: 0.245573241263
   */

  //simulation area
  float simulationArea[4];
  simulationArea[0] = -450000;
  simulationArea[1] = 6450000;
  simulationArea[2] = -2450000;
  simulationArea[3] = 1450000;

  SWE_AsagiScenario l_scenario( ASAGI_INPUT_DIR "tohoku_gebco_ucsb3_500m_hawaii_bath.nc",
                                ASAGI_INPUT_DIR "tohoku_gebco_ucsb3_500m_hawaii_displ.nc",
                                (float) 28800., simulationArea);
  #else
  // create a simple artificial scenario
  SWE_RadialDamBreakScenario l_scenario;
  #endif


  //! number of checkpoints for visualization (at each checkpoint in time, an output file is written).
  int l_numberOfCheckPoints = 3;

  //! size of a single cell in x- and y-direction
  float l_dX, l_dY;

  // compute the size of a single cell
  l_dX = (l_scenario.getBoundaryPos(BND_RIGHT) - l_scenario.getBoundaryPos(BND_LEFT) )/l_nX;
  l_dY = (l_scenario.getBoundaryPos(BND_TOP) - l_scenario.getBoundaryPos(BND_BOTTOM) )/l_nY;



	#if BLOCK_MODE==1
     SWE_WavePropagationBlock l_wavePropgationBlock(l_nX,l_nY,l_dX,l_dY);
	#elif BLOCK_MODE==2
     SWE_WaveAccumulationBlock l_wavePropgationBlock(l_nX,l_nY,l_dX,l_dY);
	#elif BLOCK_MODE==3
     SWE_WaveAccumulationBlockIntrinsicTest l_wavePropgationBlock(l_nX,l_nY,l_dX,l_dY);
	#elif BLOCK_MODE==4
     SWE_WaveAccumulationBlockIntrinsic l_wavePropgationBlock(l_nX,l_nY,l_dX,l_dY);
	#elif BLOCK_MODE==5
     SWE_MICWaveAccumulationBlockIntrinsic l_wavePropgationBlock(l_nX,l_nY,l_dX,l_dY);

    #endif


  //! origin of the simulation domain in x- and y-direction
  float l_originX, l_originY;

  // get the origin from the scenario
  l_originX = l_scenario.getBoundaryPos(BND_LEFT);
  l_originY = l_scenario.getBoundaryPos(BND_BOTTOM);

  // initialize the wave propagation block
  l_wavePropgationBlock.initScenario(l_originX, l_originY, l_scenario);


  //! time when the simulation ends.
  float l_endSimulation = l_scenario.endSimulation();

  //! checkpoints when output files are written.
  float* l_checkPoints = new float[l_numberOfCheckPoints+1];

  // compute the checkpoints in time
  for(int cp = 0; cp <= l_numberOfCheckPoints; cp++) {
     l_checkPoints[cp] = cp*(l_endSimulation/l_numberOfCheckPoints);
  }

  // Init fancy progressbar
  tools::ProgressBar progressBar(l_endSimulation);

  // write the output at time zero
  tools::Logger::logger.printOutputTime((float) 0.);
  progressBar.update(0.);

  std::string l_fileName = generateBaseFileName(l_baseName,0,0);
  //boundary size of the ghost layers
  io::BoundarySize l_boundarySize = {{1, 1, 1, 1}};
#ifdef WRITENETCDF
  //construct a NetCdfWriter
  io::NetCdfWriter l_writer( l_fileName,
		  l_wavePropgationBlock.getBathymetry(),
		  l_boundarySize,
		  l_nX, l_nY,
		  l_dX, l_dY,
		  l_originX, l_originY);
#else
  // consturct a VtkWriter
  io::VtkWriter l_writer( l_fileName,
		  l_wavePropgationBlock.getBathymetry(),
		  l_boundarySize,
		  l_nX, l_nY,
		  l_dX, l_dY );
#endif
  // Write zero time step
  l_writer.writeTimeStep( l_wavePropgationBlock.getWaterHeight(),
                          l_wavePropgationBlock.getDischarge_hu(),
                          l_wavePropgationBlock.getDischarge_hv(),
                          (float) 0.);


  /**
   * Simulation.
   */
  // print the start message and reset the wall clock time
  progressBar.clear();
  tools::Logger::logger.printStartMessage();
  tools::Logger::logger.initWallClockTime(time(NULL));

  //! simulation time.
  float l_t = 0.0;
  progressBar.update(l_t);

  unsigned int l_iterations = 0;
  double totalTimeWithClock = 0.0;
  double totalTimeWithTimeOfDay = 0.0;
  time_marker_t ticks;
  time_marker_t timeOfDay;
  // loop over checkpoints
  for(int c=1; c<=l_numberOfCheckPoints; c++) {

    // do time steps until next checkpoint is reached
    while( l_t < l_checkPoints[c] ) {

      // set values in ghost cells:
      l_wavePropgationBlock.setGhostLayer();
      
      // reset the cpu clock
      tools::Logger::logger.resetClockToCurrentTime("Cpu");

      // approximate the maximum time step
      // TODO: This calculation should be replaced by the usage of the wave speeds occuring during the flux computation
      // Remark: The code is executed on the CPU, therefore a "valid result" depends on the CPU-GPU-synchronization.
//      l_wavePropgationBlock.computeMaxTimestep();

      // compute numerical flux on each edge

      ticks = get_time();
      timeOfDay = get_time();

      l_wavePropgationBlock.computeNumericalFluxes();


      totalTimeWithClock += get_ticks_diff_time(ticks);
      totalTimeWithTimeOfDay += get_ToD_diff_time(timeOfDay);

      //! maximum allowed time step width.
      float l_maxTimeStepWidth = l_wavePropgationBlock.getMaxTimestep();

      totalTimeWithClock += get_ticks_diff_time(ticks);
      totalTimeWithTimeOfDay += get_ToD_diff_time(timeOfDay);
      // update the cpu time in the logger
      tools::Logger::logger.updateTime("Cpu");

      // update the cell values
      l_wavePropgationBlock.updateUnknowns(l_maxTimeStepWidth);

      // update the cpu time in the logger
      tools::Logger::logger.updateTime("Cpu");

      // update simulation time with time step width.
      l_t += l_maxTimeStepWidth;
      l_iterations++;


      //TODO this is for avoiding infinity
   //  break;
      // print the current simulation time
      progressBar.clear();
      tools::Logger::logger.printSimulationTime(l_t);
      progressBar.update(l_t);
    }

    // print current simulation time of the output
    progressBar.clear();
    tools::Logger::logger.printOutputTime(l_t);
    progressBar.update(l_t);

    // write output
//    l_writer.writeTimeStep( l_wavePropgationBlock.getWaterHeight(),
//                            l_wavePropgationBlock.getDischarge_hu(),
//                            l_wavePropgationBlock.getDischarge_hv(),
//                            l_t);
  }

  printf("The number of FLOPs: %f\n", l_wavePropgationBlock.flops);
  printf("Time with clock(): %f\n", totalTimeWithClock);
  printf("Time with timeofday(): %f\n", totalTimeWithTimeOfDay);
  printf("GFLOPS with clock(): %f\n", l_wavePropgationBlock.flops/(totalTimeWithClock*1e09));
  printf("GFLOPS with timeofday: %f\n", l_wavePropgationBlock.flops/(totalTimeWithTimeOfDay*1e09));

  /**
   * Finalize.
   */
  // write the statistics message
  progressBar.clear();
  tools::Logger::logger.printStatisticsMessage();

  // print the cpu time
  tools::Logger::logger.printTime("Cpu", "CPU time");

  // print the wall clock time (includes plotting)
  tools::Logger::logger.printWallClockTime(time(NULL));

  // printer iteration counter
  tools::Logger::logger.printIterationsDone(l_iterations);

  return 0;
}
