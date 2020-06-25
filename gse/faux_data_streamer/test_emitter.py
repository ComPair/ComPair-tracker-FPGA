import time
import silayer

import numpy as np


if __name__ == "__main__":

	faux_data_iterator = silayer.raw2hdf.lame_byte_iterator('../layer_daq/ramp0.rdat')

	t0 = time.time()
	t = np.zeros(1000)
	for i in range(len(t)):
		next(faux_data_iterator)
		t[i] = time.time()

	average = 1000*(np.mean(t) - t0)/len(t)
	print(f"Average time: {average} ms")
		



