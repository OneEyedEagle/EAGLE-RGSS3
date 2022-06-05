# x = 0.0 ~ 1.0
shakeLevel = 3.0;
shakeDelta = 0.005
p x = shakeDelta * (-1.0 + shakeLevel * rand());
