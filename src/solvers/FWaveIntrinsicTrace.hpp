/**
 * FWaveVec.h
 *
 ****
 **** This is a vectorizable C++ implementation of the F-Wave solver (FWave.hpp).
 **** It runs with intrisic instructions
 ****
 *
 * Created on: Nov 13, 2012
 * Last Upsate: Dec 28, 2013
 *
 ****
 *
 *  Author: Sebastian Rettenberger
 *    Homepage: http://www5.in.tum.de/wiki/index.php/Sebastian_Rettenberger,_M.Sc.
 *    E-Mail: rettenbs AT in.tum.de
 *  Some optimzations: Michael Bader
 *    Homepage: http://www5.in.tum.de/wiki/index.php/Michael_Bader
 *    E-Mail: bader AT in.tum.de
 *
 ****
 *
 * (Main) Literature:
 *
 *   @article{bale2002wave,
 *            title={A wave propagation method for conservation laws and balance laws with spatially varying flux functions},
 *            author={Bale, D.S. and LeVeque, R.J. and Mitran, S. and Rossmanith, J.A.},
 *            journal={SIAM Journal on Scientific Computing},
 *            volume={24},
 *            number={3},
 *            pages={955--978},
 *            year={2002}}
 *
 *   @book{leveque2002finite,
 *         Author = {LeVeque, R. J.},
 *         Publisher = {Cambridge University Press},
 *         Title = {Finite Volume Methods for Hyperbolic Problems},
 *         Volume = {31},
 *         Year = {2002}}
 *
 *   @webpage{levequeclawpack,
 *            Author = {LeVeque, R. J.},
 *            Lastchecked = {January, 05, 2011},
 *            Title = {Clawpack Sofware},
 *            Url = {https://github.com/clawpack/clawpack-4.x/blob/master/geoclaw/2d/lib}}
 *
 ****
 */

#ifndef FWAVEISIC_HPP_
#define FWAVEISIC_HPP_
#define VEC_SIZE 8
#include <cmath>
#include <immintrin.h>
#include <cstring>
#include <iostream>

namespace solver
{

/**
 *
 */
template<typename T>
class FWaveIntrinsicTrace
{
private:
	const T dryTol;
	const T half_gravity; // 0.5 * gravity constant
	const T sqrt_gravity; // square root of the gravity constant
	const T zeroTol;

public:
	/**
	 * FWaveVec Constructor, takes three problem parameters
	 * @param dryTol "dry tolerance": if the water height falls below dryTol, wall boundary conditions are applied (default value is 100)
	 * @param gravity takes the value of the gravity constant (default value is 9.81 m/s^2)
	 * @param zeroTol computed f-waves with an absolute value < zeroTol are treated as static waves (default value is 10^{-7})
	 */
	FWaveIntrinsicTrace(T i_dryTol = (T) 1.0,
			 T i_gravity = (T) 9.81,
			 T i_zeroTol = (T) 0.0000001)
		: dryTol(i_dryTol),
		  half_gravity( (T).5 * i_gravity ),
		  sqrt_gravity( std::sqrt(i_gravity) ),
		  zeroTol(i_zeroTol)
	{
	}

	void print_isic(__m256 intr,std::string label,int traceon) const{
		 float rest4[VEC_SIZE] __attribute__((aligned(64)));
		 _mm256_store_ps(rest4,intr);
		 if (traceon==0) return;
		 cout.precision(15);
		 for(int i=0; i<VEC_SIZE; i++){
			 cout << label << " " << i << " " << rest4[i] << "\n";

		 }
	}

	/**
	 * takes the water height, discharge and bathymatry in the left and right cell
	 * and computes net upsates (left and right going waves) according to the f-wave approach.
	 * It also returns the maximum wave speed.
	 */
	void computeNetUpdates ( __m256 i_hLeft,  __m256 i_hRight,
							 __m256 i_huLeft, __m256 i_huRight,
							 __m256 i_bLeft,  __m256 i_bRight,

							 __m256 &o_hUpsateLeft,
							 __m256 &o_hUpsateRight,
							 __m256 &o_huUpsateLeft,
							 __m256 &o_huUpsateRight,
							 __m256 &o_maxWaveSpeed, int traceon ) const
	{

//					print_isic (i_hRight,"i_hRight1",traceon);
//					print_isic (i_hLeft,"i_hLeft1-",traceon);
//					print_isic (i_bRight,"bRight1-",traceon);
//					print_isic (i_bLeft,"bLeft1-",traceon);
//					print_isic (i_huRight,"prei_huRight-",traceon);
//					print_isic (i_huLeft,"i_prehuLeft-",traceon);

			__m256 dryTol_vec= _mm256_set1_ps (dryTol);
			__m256 zero_vec= _mm256_setzero_ps() ;

			//these are the conditions for the first if

			__m256 mask1a = _mm256_cmp_ps(i_hLeft,dryTol_vec, _CMP_GE_OQ );
			__m256 mask1 = _mm256_cmp_ps(i_hRight,dryTol_vec, _CMP_LT_OQ );

			mask1= _mm256_and_ps (mask1, mask1a);

			//Enter the first if
			__m256 minus_i_huLeft=_mm256_sub_ps(zero_vec,i_huLeft);
			i_hRight= _mm256_blendv_ps (i_hRight,i_hLeft, mask1);
			i_huRight=_mm256_blendv_ps(i_huRight,minus_i_huLeft,mask1);
			i_bRight=_mm256_blendv_ps(i_bRight,i_bLeft,mask1 );

			__m256 mask2 = _mm256_cmp_ps(i_hRight,dryTol_vec,_CMP_GE_OQ);
			//the second if enters if mask2 is true and the first mask is false (else-if)
			mask2 = _mm256_andnot_ps(mask1a,mask2);

			//We blend according to the mask
			__m256 minus_i_huRight= _mm256_sub_ps(zero_vec, i_huRight);
			i_hLeft =_mm256_blendv_ps(i_hLeft,i_hRight, mask2);
			i_huLeft = _mm256_blendv_ps(i_huLeft,minus_i_huRight, mask2 );
			i_bLeft = _mm256_blendv_ps(i_bLeft, i_bRight,mask2);

			//We calculate the else mask as the negation of the OR of the other two masks
			//To avoid the negation we just invert the order of the parameters in the blends

			mask1= _mm256_or_ps(mask1a,mask2);


			i_hLeft = _mm256_blendv_ps(dryTol_vec,i_hLeft,mask1);
			i_huLeft =_mm256_blendv_ps(zero_vec,i_huLeft,mask1);
			i_bLeft =_mm256_blendv_ps(zero_vec,i_bLeft,mask1);
			i_huRight =_mm256_blendv_ps(zero_vec,i_huRight,mask1 );
			i_bRight = _mm256_blendv_ps(zero_vec,i_bRight, mask1 );
			i_hRight = _mm256_blendv_ps(dryTol_vec,i_hRight, mask1);
			print_isic (i_bRight,"post2riight",traceon);

			//__m256 uLeft = i_huLeft / i_hLeft;
			__m256 uLeft =_mm256_div_ps(i_huLeft,i_hLeft);
			//__m256 uRight = i_huRight / i_hRight;
			__m256 uRight =_mm256_div_ps(i_huRight,i_hRight );

			//! wave speeds of the f-waves
			//__m256 waveSpeeds0 = 0., waveSpeeds1 = 0.;

			__m256 waveSpeeds0 =zero_vec;
			__m256 waveSpeeds1 =zero_vec;
			print_isic (i_hRight,"i_hRightii",traceon);
			print_isic (i_hLeft,"i_hLeftii",traceon);
			print_isic (i_bRight,"prerightii",traceon);
			print_isic (i_bLeft,"preLeftii",traceon);
			print_isic (i_huRight,"prei_huRight",traceon);
			print_isic (i_huLeft,"i_prei_huLeft",traceon);

			/*
			 * ComputeWaveSpeeds begins here
			 */
			__m256 sqrt_hLeft =_mm256_sqrt_ps(i_hLeft); 	 		//sqrt_hRight = std::sqrt(i_hRight);                              // 1 FLOP (sqrt)
			__m256 sqrt_hRight=_mm256_sqrt_ps(i_hRight);


			__m256 sqrt_gravity_vec=_mm256_set1_ps(sqrt_gravity);
			  // compute eigenvalues of the jacobian matrices
			 	 		// in states Q_{i-1} and Q_{i}
			 	 		//T characteristicSpeed0 = i_uLeft - sqrt_gravity * sqrt_hLeft;     // 2 FLOPs

			 	__m256 characteristicSpeed0 = _mm256_mul_ps(sqrt_hLeft,sqrt_gravity_vec);
			 	 		characteristicSpeed0 = _mm256_sub_ps(uLeft,characteristicSpeed0);
			 	 		//T characteristicSpeed1 = i_uRight + sqrt_gravity * sqrt_hRight;   // 2 FLOPs
			 	__m256 characteristicSpeed1 = _mm256_mul_ps(sqrt_hRight,sqrt_gravity_vec);
			 	 		characteristicSpeed1=  _mm256_add_ps(uRight,characteristicSpeed1);
			 	 		//print_isic (characteristicSpeed0,"characteristicSpeed0i",traceon);
			 	 		//print_isic (characteristicSpeed1,"characteristicSpeed1i",traceon);
			 	 		// compute "Roe averages"
			 	 				//T hRoe = (T).5 * (i_hRight + i_hLeft);                            // 2 FLOPs
			 	__m256 half= _mm256_set1_ps(0.5f);
			    __m256 hRoe= _mm256_add_ps(i_hRight,i_hLeft);
			     		hRoe= _mm256_mul_ps (hRoe, half);

			 	//T sqrt_hRoe = std::sqrt(hRoe);                                    // 1 FLOP (sqrt)
			 	 __m256 sqrt_hRoe = _mm256_sqrt_ps(hRoe);
			 	// uRoe = i_uLeft * sqrt_hLeft + i_uRight * sqrt_hRight;
			 	__m256 uRoe = _mm256_mul_ps(uRight,sqrt_hRight);
			 	__m256 op2  = _mm256_mul_ps(uLeft,sqrt_hLeft);
			 	uRoe	     = _mm256_add_ps(uRoe, op2);

			 	 //uRoe /= sqrt_hLeft + sqrt_hRight;                                 // 2 FLOPs (1 div)
			 	 op2= _mm256_add_ps(sqrt_hLeft, sqrt_hRight);
			 	 uRoe= _mm256_div_ps(uRoe,op2 );

			 	 // compute "Roe speeds" from Roe averages
			 	 //T roeSpeed0 = uRoe - sqrt_gravity * sqrt_hRoe;                    // 2 FLOPs

			 	 op2 = _mm256_mul_ps(sqrt_gravity_vec,sqrt_hRoe);
			 	 __m256 roeSpeed0 = _mm256_sub_ps(uRoe,op2);

			 	 //T roeSpeed1 = uRoe + sqrt_gravity * sqrt_hRoe;                    // 2 FLOPs
			 	 __m256 roeSpeed1 =_mm256_add_ps(uRoe,op2);

			 	waveSpeeds0 = _mm256_min_ps(characteristicSpeed0, roeSpeed0);         // 1 FLOP (min)
			 	waveSpeeds1 = _mm256_max_ps(characteristicSpeed1, roeSpeed1);         // 1 FLOP (max)
			/**
			 * End of ComputeWaveSpeeds
			 */

			 	//print_isic (waveSpeeds0,"waveSpeeds0i",traceon);
			 	//print_isic (waveSpeeds1,"waveSpeeds1i",traceon);
			__m256 fWaves0 = zero_vec;
			__m256 fWaves1 = zero_vec;
			/*
			 * This is the computeWaveDecomposition
			 */
			__m256 fDif0= _mm256_sub_ps(i_huRight,i_huLeft);

					 // T fDif1 = i_huRight * i_uRight + half_gravity * i_hRight * i_hRight
					  //        -(i_huLeft  * i_uLeft  + half_gravity * i_hLeft  * i_hLeft);   // 9 FLOPs

			__m256 half_gravity_vec=_mm256_set1_ps(half_gravity);

			__m256 op1=_mm256_mul_ps(i_huLeft, uLeft);
			op2=_mm256_mul_ps(i_hLeft ,i_hLeft);
			print_isic (op2,"sqr1",traceon);
			op2=_mm256_mul_ps(op2, half_gravity_vec);
			op2=_mm256_add_ps(op1,op2);
					  //second line
			op1=_mm256_mul_ps(i_huRight,uRight);
			__m256 op3= _mm256_mul_ps(i_hRight, i_hRight);
			print_isic (op3,"sqr2",traceon);
			op3= _mm256_mul_ps( op3, half_gravity_vec);
			op1= _mm256_add_ps(op1,op3);

			__m256 fDif1= _mm256_sub_ps(op1,op2);

			print_isic (op1,"op1-",traceon);
			print_isic (op2,"op2",traceon);
			//print_isic (fDif1,"fDif1i",traceon);
			//print_isic (half_gravity_vec,"half_gravity",traceon);
					 //fDif1 += half_gravity * (i_hRight + i_hLeft)*(i_bRight - i_bLeft);     // 5 FLOPs
//			print_isic (i_hRight,"i_hRighti",traceon);
//			print_isic (i_hLeft,"i_hLefti",traceon);
//			print_isic (i_bRight,"i_bRighti",traceon);
//			print_isic (i_bLeft,"i_bLefti",traceon);
			op1=_mm256_sub_ps(i_bRight,i_bLeft);
			//print_isic (op1,"op1");
			op2=_mm256_add_ps(i_hRight, i_hLeft);
			//print_isic (op2,"op2");
			op1=_mm256_mul_ps(op1,op2);
			op2=_mm256_mul_ps(op1,half_gravity_vec);
			fDif1=_mm256_add_ps(fDif1,op2);

			print_isic (fDif0,"fDif0i",traceon);
			print_isic (fDif1,"fDif1i",traceon);

					 //T inverseSpeedDiff = (T)1. / ( i_waveSpeed1 - i_waveSpeed0 );          // 2 FLOPs (1 div)
			op1=_mm256_set1_ps(1);
			op2=_mm256_sub_ps(waveSpeeds1, waveSpeeds0);
			__m256 inverseSpeedDiff= _mm256_div_ps(op1,op2);
			print_isic (inverseSpeedDiff,"inverseSpeedDiff",traceon);
			//print_isic (inverseSpeedDiff,"inverseSpeedDiffi");
			// o_fWave0 = (  i_waveSpeed1 * fDif0 - fDif1 ) * inverseSpeedDiff;
			op1= _mm256_mul_ps(fDif0 , waveSpeeds1);
			op2= _mm256_sub_ps(op1, fDif1);


			fWaves0=_mm256_mul_ps(op2,inverseSpeedDiff);
					 // o_fWave1 = ( -i_waveSpeed0 * fDif0 + fDif1 ) * inverseSpeedDiff;
			__m256 zerov=_mm256_set1_ps(0);
			op2= _mm256_mul_ps(waveSpeeds0,fDif0 );
			__m256 substr=_mm256_sub_ps(zerov,op2);
			__m256 rg= _mm256_add_ps(substr,fDif1 );

			print_isic (substr,"substr",traceon);
			print_isic (op2,"op2",traceon);
			print_isic (rg,"rg",traceon);
			fWaves1=_mm256_mul_ps(rg,inverseSpeedDiff ) ;
			/*
			 * End of the computeWaveDecomposition
			 */

			print_isic (fWaves0,"fWaves0i",traceon);
			print_isic (fWaves1,"fWaves1i",traceon);
			 o_hUpsateLeft =zero_vec;
			 o_hUpsateRight = zero_vec;
			 o_huUpsateLeft = zero_vec;
			 o_huUpsateRight = zero_vec;



			//second if block
			__m256 zeroTol_vec= _mm256_set1_ps (zeroTol);
			__m256 minus_zeroTol = _mm256_sub_ps(zero_vec,zeroTol_vec);

			//if(waveSpeeds0 < -zeroTol)
			mask1 = _mm256_cmp_ps(waveSpeeds0,minus_zeroTol, _CMP_LT_OQ );

			__m256 toAdd1= _mm256_add_ps(o_hUpsateLeft,fWaves0);
			__m256 fwa_times_wa= _mm256_mul_ps(fWaves0,waveSpeeds0);
			__m256 toAdd2=_mm256_add_ps(fwa_times_wa,o_huUpsateLeft);
			o_hUpsateLeft= _mm256_blendv_ps (o_hUpsateLeft,toAdd1,mask1);
			o_huUpsateLeft = _mm256_blendv_ps (o_huUpsateLeft,toAdd2,  mask1);

			//enters to the elseif after creating the mask
			// else if (waveSpeeds0 > zeroTol

			mask2= _mm256_cmp_ps(waveSpeeds0,zeroTol_vec, _CMP_GT_OQ);
			//introduce fix for else
			mask2= _mm256_and_ps(mask1,mask2);
			//the operands are the same as the previous ifs
			toAdd1=_mm256_add_ps(o_hUpsateRight,fWaves0);
			toAdd2=_mm256_add_ps(fwa_times_wa,o_huUpsateRight);

			o_hUpsateRight=_mm256_blendv_ps(o_hUpsateRight,toAdd1, mask2);
			o_huUpsateRight = _mm256_blendv_ps(o_huUpsateRight,toAdd2, mask2 );


			//the else is the nor of the previous masks, to avoid or order of the parameters in blend is inverted
			mask1= _mm256_or_ps(mask1,mask2);
			__m256 zeroFive_vec= _mm256_set1_ps(0.5f);

			__m256 prod1= _mm256_mul_ps(zeroFive_vec,fWaves0);
			__m256 prod2= _mm256_mul_ps(prod1, waveSpeeds0);

			toAdd1=_mm256_add_ps(prod1, o_hUpsateLeft);
			toAdd2= _mm256_add_ps(prod2, o_huUpsateLeft);
			__m256 toAdd3= _mm256_add_ps(prod1,o_hUpsateRight);
			__m256 toAdd4= _mm256_add_ps(prod2,o_huUpsateRight);

			o_hUpsateLeft =_mm256_blendv_ps(toAdd1,o_hUpsateLeft,mask1 );
			o_huUpsateLeft = _mm256_blendv_ps( toAdd2, o_huUpsateLeft,mask1);
			o_hUpsateRight = _mm256_blendv_ps(toAdd3,o_hUpsateRight,mask1 );
			o_huUpsateRight = _mm256_blendv_ps(toAdd4,o_huUpsateRight,mask1 );


			//third if block, similar to the last block

			mask1 = _mm256_cmp_ps(waveSpeeds1,zeroTol_vec, _CMP_GT_OQ );

			toAdd1= _mm256_add_ps(o_hUpsateRight,fWaves1);
			fwa_times_wa= _mm256_mul_ps(fWaves1,waveSpeeds1);
			toAdd2=_mm256_add_ps(fwa_times_wa,o_huUpsateRight);
			o_hUpsateRight= _mm256_blendv_ps (o_hUpsateRight,toAdd1,mask1);
			o_huUpsateRight = _mm256_blendv_ps (o_huUpsateRight,toAdd2,  mask1);

			//enters to the elseif after creating the mask

			//2nd wave family
			mask2= _mm256_and_ps(mask1,mask2);
			mask2= _mm256_cmp_ps(waveSpeeds1,minus_zeroTol, _CMP_LT_OQ);
			//the operands are the same as the previous ifs
			toAdd1=_mm256_add_ps(o_hUpsateLeft,fWaves1);
			toAdd2=_mm256_add_ps(fwa_times_wa,o_huUpsateLeft);

			o_hUpsateLeft=_mm256_blendv_ps(o_hUpsateLeft,toAdd1, mask2);
			o_huUpsateLeft = _mm256_blendv_ps(o_huUpsateLeft,toAdd2, mask2 );

			//the else is the nor of the previous masks, to avoid not order of the parameters in blend is inverted
			mask1= _mm256_or_ps(mask1,mask2);


			prod1= _mm256_mul_ps(zeroFive_vec,fWaves1);
			prod2= _mm256_mul_ps(prod1, waveSpeeds1);

			toAdd1=_mm256_add_ps(prod1, o_hUpsateLeft);
			toAdd2= _mm256_add_ps(prod2, o_huUpsateLeft);
			toAdd3= _mm256_add_ps(prod1,o_hUpsateRight);
			toAdd4= _mm256_add_ps(prod2,o_huUpsateRight);

			//the changes to the original vars are applied here
			o_hUpsateLeft =_mm256_blendv_ps(toAdd1,o_hUpsateLeft,mask1 );
			o_huUpsateLeft = _mm256_blendv_ps(toAdd2,  o_huUpsateLeft,mask1);
			o_hUpsateRight = _mm256_blendv_ps(toAdd3,o_hUpsateRight,mask1 );
			o_huUpsateRight = _mm256_blendv_ps(toAdd4,o_huUpsateRight,mask1 );

			//absolute values of floats must be computed manually in SNB
			//check for negatives
			__m256 neg_wave0_mask=_mm256_cmp_ps(waveSpeeds0,zero_vec, _CMP_LT_OQ);
			__m256	neg_wave1_mask=_mm256_cmp_ps(waveSpeeds1,zero_vec, _CMP_LT_OQ);
			//compute negatives
			__m256 minus_one= _mm256_set1_ps (-1);
			__m256 neg_wave0=_mm256_mul_ps(waveSpeeds0,minus_one);
			__m256 neg_wave1=_mm256_mul_ps(waveSpeeds1,minus_one);

			//multiply the ones below 0 by minus 1
			neg_wave0=_mm256_blendv_ps(waveSpeeds0,neg_wave0,neg_wave0_mask);
			neg_wave1=_mm256_blendv_ps(waveSpeeds1,neg_wave1,neg_wave1_mask);
			print_isic (o_hUpsateLeft,"o_hUpsateLefti",traceon);
			//print_isic (o_hUpsateRight,"o_hUpsateRighti");
			print_isic (o_hUpsateLeft,"o_huUpsateLefti",traceon);
			//print_isic (o_hUpsateRight,"o_huUpsateRighti");
			o_maxWaveSpeed =_mm256_max_ps(neg_wave0,neg_wave1);
    }




};

}

#endif // FWAVEVEC
