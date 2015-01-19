/**
 * @file
 * This file is part of SWE.
 *
 * @author Alexander Breuer (breuera AT in.tum.de, http://www5.in.tum.de/wiki/index.php/Dipl.-Math._Alexander_Breuer)
 * @author Sebastian Rettenberger (rettenbs AT in.tum.de, http://www5.in.tum.de/wiki/index.php/Sebastian_Rettenberger,_M.Sc.)
 * @author Michael Bader (bader AT in.tum.de, http://www5.in.tum.de/wiki/index.php/Michael_Bader)
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
 * SWE_Block, which uses solvers in the wave propagation formulation.
 */

#include <cassert>
#include <cstring>
#include <limits>

#include "SWE_WaveAccumulationBlockIntrinsic.hh"
#include <immintrin.h>
#include <zmmintrin.h>
#ifdef LOOP_OPENMP
#include <omp.h>
#endif
#define VEC_SIZE 8

/**
 * Constructor of a SWE_WaveAccumulationBlock.
 *
 * Allocates the variables for the simulation:
 *   unknowns h,hu,hv,b are defined on grid indices [0,..,nx+1]*[0,..,ny+1] (-> Abstract class SWE_Block)
 *     -> computational domain is [1,..,nx]*[1,..,ny]
 *     -> plus ghost cell layer
 *
 * Similar, all net-updates are defined as cell-local variables with indices [0,..,nx+1]*[0,..,ny+1], 
 * however, only values on [1,..,nx]*[1,..,ny] are used (i.e., ghost layers are not accessed).
 * Net updates are intended to hold the accumulated(!) net updates computed on the edges.
 *
 */
SWE_WaveAccumulationBlockIntrinsic::SWE_WaveAccumulationBlockIntrinsic(
		int l_nx, int l_ny,
		float l_dx, float l_dy):
  SWE_Block(l_nx, l_ny, l_dx, l_dy),
  hNetUpdates (nx+2, ny+2),
  huNetUpdates(nx+2, ny+2),
  hvNetUpdates(nx+2, ny+2)
{}





/**
 * Compute net updates for the block.
 * The member variable #maxTimestep will be updated with the 
 * maximum allowed time step size
 */
void SWE_WaveAccumulationBlockIntrinsic::computeNumericalFluxes() {

	float dx_inv = 1.0f/dx;
	float dy_inv = 1.0f/dy;

	//maximum (linearized) wave speed within one iteration
	float maxWaveSpeed = (float) 0.;

	// compute the net-updates for the vertical edges

#ifdef LOOP_OPENMP
#pragma omp parallel
{
	// thread-local maximum wave speed:
	float l_maxWaveSpeed = (float) 0.;

	// Use OpenMP for the outer loop
	#pragma omp for
#endif // LOOP_OPENMP
	for(int i = 1; i < nx+2; i++) {
		const int ny_end = ny+2;	// compiler might refuse to vectorize j-loop without this ...

        for(int j = 1; j < ny_end; j+=16) {
			//cout << "BEGIN 1LOOP  \n" << i << " " << j <<"\n";

            float maxEdgeSpeed[16];
            float hNetUpLeft[16], hNetUpRight[16];
            float huNetUpLeft[16], huNetUpRight[16];


            __m512 hLeft= _mm512_load_ps(&h[i-1][j]);
            __m512 hRight = _mm512_load_ps(&h[i][j]);
            __m512 huLeft = _mm512_load_ps(&hu[i-1][j]);
            __m512 huRight = _mm512_load_ps(&hu[i][j]);
            __m512 bLeft = _mm512_load_ps(&b[i-1][j]);
            __m512 bRight = _mm512_load_ps(&b[i][j]);


			// accumulate net updates to cell-wise net updates for h and hu
//				hNetUpdates[i-1][j]  += dx_inv * hNetUpLeft;
//				huNetUpdates[i-1][j] += dx_inv * huNetUpLeft;
//				hNetUpdates[i][j]    += dx_inv * hNetUpRight;
//				huNetUpdates[i][j]   += dx_inv * huNetUpRight;

                __m512 o_hUpsateLefti, o_hUpsateRighti, o_huUpsateLefti,
							o_huUpsateRighti, o_maxWaveSpeedi;

							wavePropagationSolver.computeNetUpdates( hLeft, hRight,
												huLeft, huRight, bLeft, bRight,
												o_hUpsateLefti, o_hUpsateRighti, o_huUpsateLefti,
												o_huUpsateRighti,  o_maxWaveSpeedi);


            __m512 dy_inv_vec=_mm512_set1_ps(dy_inv);

			//							hNetUpdates[i][k+j-1]  += dy_inv * hNetUpDow[k];
			//							hvNetUpdates[i][k+ j-1] += dy_inv * hvNetUpDow[k];
			//							hNetUpdates[i][k+j]    += dy_inv * hNetUpUpw[k];
			//							hvNetUpdates[i][k+j]   += dy_inv * hvNetUpUpw[k];

            __m512 op1 = _mm512_mul_ps(o_hUpsateLefti,dy_inv_vec);
            __m512 op2 = _mm512_mul_ps(o_hUpsateRighti,dy_inv_vec);
            __m512 op3 = _mm512_mul_ps(o_huUpsateLefti,dy_inv_vec);
            __m512 op4 = _mm512_mul_ps(o_huUpsateRighti,dy_inv_vec);

            __m512 h1Ups = _mm512_load_ps(&hNetUpdates[i][j-1]);
            __m512 hv1Ups =_mm512_load_ps(&hvNetUpdates[i][j-1]);
            __m512 h2Ups = _mm512_load_ps(&hNetUpdates[i][j]);
            __m512 hv2Ups =_mm512_load_ps(&hvNetUpdates[i][j]);

            h1Ups = _mm512_add_ps(op1,h1Ups);
            hv1Ups =_mm512_add_ps(op2,hv1Ups);
            h2Ups = _mm512_add_ps(op3,h2Ups);
            hv2Ups =_mm512_add_ps(op4,hv2Ups);

            _mm512_store_ps(&hNetUpdates[i][j-1],h1Ups);
            _mm512_store_ps(&hvNetUpdates[i][j-1],hv1Ups);
            _mm512_store_ps(&hNetUpdates[i][j],h2Ups);
            _mm512_store_ps(&hvNetUpdates[i][j],hv2Ups);

			float maxspeeds[VEC_SIZE] __attribute__((aligned(64)));

            _mm512_store_ps(maxspeeds,o_maxWaveSpeedi);

			for(int x=0; x<VEC_SIZE; x++){
					maxWaveSpeed = std::max(maxWaveSpeed, maxspeeds[x]);
			}


			#ifdef LOOP_OPENMP
				//update the thread-local maximum wave speed
				l_maxWaveSpeed = std::max(l_maxWaveSpeed, maxEdgeSpeed);
			#endif // LOOP_OPENMP
		}
	}
	flops += 58*ny*(nx+1);

	// compute the net-updates for the horizontal edges

	/**
	 * Note: because of use of vectors ny must be a multiple of 8, less 1
	 */

#ifdef LOOP_OPENMP // Use OpenMP for the outer loop
	//#pragma omp for
#endif // LOOP_OPENMP
	for(int i = 1; i < nx+2; i++) {
		const int ny_end = ny+2;	// compiler refused to vectorize j-loop without this ...

		//There is a leap of 8 for each iteration
        for(int j = 1; j < ny_end; j+=16) {
            float maxEdgeSpeed[16];
            float hNetUpDow[16], hNetUpUpw[16];
            float hvNetUpDow[16], hvNetUpUpw[16];


			//the registers sent to computeNetUpdates are loaded
            __m512 hLeft= _mm512_load_ps(&h[i][j-1]);
            __m512 hRight =  _mm512_load_ps(&h[i][j]);
            __m512 hvLeft =  _mm512_load_ps(&hv[i][j-1]);
            __m512 hvRight = _mm512_load_ps(&hv[i][j]);
            __m512 bLeft = _mm512_load_ps(&b[i][j-1]);
            __m512 bRight = _mm512_load_ps(&b[i][j]);

		//	cout << "BEGIN 2LOOP  \n" << i << " " << j <<"\n";
			int trace=0;
			int trace2=0;
			float maxWaveSpeedt;


			//registers where results are obtained

            __m512 o_hUpsateLefti, o_hUpsateRighti, o_huUpsateLefti,
			o_huUpsateRighti, o_maxWaveSpeedi;

			wavePropagationSolver.computeNetUpdates( hLeft, hRight,
								hvLeft, hvRight, bLeft, bRight,
								o_hUpsateLefti, o_hUpsateRighti, o_huUpsateLefti,
								o_huUpsateRighti,  o_maxWaveSpeedi);


            __m512 dy_inv_vec = _mm512_set1_ps(dy_inv);

			//							hNetUpdates[i][k+j-1]  += dy_inv * hNetUpDow[k];
			//							hvNetUpdates[i][k+ j-1] += dy_inv * hvNetUpDow[k];
			//							hNetUpdates[i][k+j]    += dy_inv * hNetUpUpw[k];
			//							hvNetUpdates[i][k+j]   += dy_inv * hvNetUpUpw[k];

            __m512 op1 = _mm512_mul_ps(o_hUpsateLefti,dy_inv_vec);
            __m512 op2 = _mm512_mul_ps(o_hUpsateRighti,dy_inv_vec);
            __m512 op3 = _mm512_mul_ps(o_huUpsateLefti,dy_inv_vec);
            __m512 op4 = _mm512_mul_ps(o_huUpsateRighti,dy_inv_vec);

            __m512 h1Ups = _mm512_load_ps(&hNetUpdates[i][j-1]);
            __m512 hv1Ups =_mm512_load_ps(&hvNetUpdates[i][j-1]);
            __m512 h2Ups = _mm512_load_ps(&hNetUpdates[i][j]);
            __m512 hv2Ups =_mm512_load_ps(&hvNetUpdates[i][j]);

             h1Ups = _mm512_add_ps(op1,h1Ups);
             hv1Ups =_mm512_add_ps(op2,hv1Ups);
             h2Ups = _mm512_add_ps(op3,h2Ups);
             hv2Ups =_mm512_add_ps(op4,hv2Ups);

             _mm512_store_ps(&hNetUpdates[i][j-1],h1Ups);
             _mm512_store_ps(&hvNetUpdates[i][j-1],hv1Ups);
             _mm512_store_ps(&hNetUpdates[i][j],h2Ups);
             _mm512_store_ps(&hvNetUpdates[i][j],hv2Ups);

			float maxspeeds[VEC_SIZE] __attribute__((aligned(64)));

            _mm512_store_ps(maxspeeds,o_maxWaveSpeedi);

			for(int x=0; x<VEC_SIZE; x++){
				maxWaveSpeed = std::max(maxWaveSpeed, maxspeeds[x]);
			}



			#ifdef LOOP_OPENMP
				//update the thread-local maximum wave speed
				l_maxWaveSpeed = std::max(l_maxWaveSpeed, maxEdgeSpeed[0]);
			#else // LOOP_OPENMP
				//update the maximum wave speed
				maxWaveSpeed = std::max(maxWaveSpeed, maxEdgeSpeed[0]);
			#endif // LOOP_OPENMP


			}
	}
	flops += 58*ny*nx;

#ifdef LOOP_OPENMP
	#pragma omp critical
	{
		maxWaveSpeed = std::max(l_maxWaveSpeed, maxWaveSpeed);
	}

} // #pragma omp parallel
#endif

	if(maxWaveSpeed > 0.00001) {
		//TODO zeroTol

		//compute the time step width
		//CFL-Codition
		//(max. wave speed) * dt / dx < .5
		// => dt = .5 * dx/(max wave speed)

		maxTimestep = std::min( dx/maxWaveSpeed, dy/maxWaveSpeed );

		// reduce maximum time step size by "safety factor"
		maxTimestep *= (float) .4; //CFL-number = .5
	} else
		//might happen in dry cells
		maxTimestep = std::numeric_limits<float>::max();
}

/**
 * Updates the unknowns with the already computed net-updates.
 *
 * @param dt time step width used in the update.
 */
void SWE_WaveAccumulationBlockIntrinsic::updateUnknowns(float dt) {

  //update cell averages with the net-updates
#ifdef LOOP_OPENMP
	#pragma omp parallel for
#endif // LOOP_OPENMP
	for(int i = 1; i < nx+1; i++) {

#ifdef VECTORIZE
		// Tell the compiler that he can safely ignore all dependencies in this loop
		#pragma ivdep
#endif // VECTORIZE
		for(int j = 1; j < ny+1; j++) {

			h[i][j]  -= dt * hNetUpdates[i][j];
			hu[i][j] -= dt * huNetUpdates[i][j];
			hv[i][j] -= dt * hvNetUpdates[i][j];

			hNetUpdates[i][j] = (float) 0;
			huNetUpdates[i][j] = (float) 0;
			hvNetUpdates[i][j] = (float) 0;

			//TODO: proper dryTol
			if (h[i][j] < 0.1)
				hu[i][j] = hv[i][j] = 0.; //no water, no speed!

			if (h[i][j] < 0) {
#ifndef NDEBUG
				// Only print this warning when debug is enabled
				// Otherwise we cannot vectorize this loop
				if (h[i][j] < -0.1) {
					std::cerr << "Warning, negative height: (i,j)=(" << i << "," << j << ")=" << h[i][j] << std::endl;
					std::cerr << "         b: " << b[i][j] << std::endl;
				}
#endif // NDEBUG
				//zero (small) negative depths
				h[i][j] = (float) 0;
			}
		}
	}
	flops += 6*ny*nx;
}

/**
 * Update the bathymetry values with the displacement corresponding to the current time step.
 *
 * @param i_asagiScenario the corresponding ASAGI-scenario
 */
#ifdef DYNAMIC_DISPLACEMENTS
bool SWE_WaveAccumulationBlock::updateBathymetryWithDynamicDisplacement(scenarios::Asagi &i_asagiScenario, const float i_time) {
  if (!i_asagiScenario.dynamicDisplacementAvailable(i_time))
    return false;

  // update the bathymetry
  for(int i=0; i<=nx+1; i++) {
    for(int j=0; j<=ny+1; j++) {
      b[i][j] = i_asagiScenario.getBathymetryAndDynamicDisplacement( offsetX + (i-0.5f)*dx,
                                                                     offsetY + (j-0.5f)*dy,
                                                                     i_time
                                                                   );
    }
  }

  setBoundaryBathymetry();

  return true;
}
#endif
