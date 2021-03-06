function results = runLassoGlm(X, y, testIdx, options, CVB, method)
%% hold out the test set
X_train = X(~testIdx,:);
X_test = X(testIdx,:);
y_train = y(~testIdx);
y_test = y(testIdx);

%% voxel-wise standardization
[X_train, X_test] = columnNormalization(X_train, X_test);

%% cvfit lasso with with CVGLMNET
if strcmp(method, 'glmnet')
    options.nlambda = 100;
%     options.maxit = 1e5;
    cvfit = cvglmnet(X_train,y_train, 'binomial',options,'class',CVB);
    
    y_hat = cvglmnetPredict(cvfit, X_test, 'lambda_min');
    min_lambda = cvfit.lambda_min;
    coef = cvglmnetCoef(cvfit,'lambda_min');
    
elseif strcmp(method, 'lassoglm')
    %% cvfit lasso with lassoglm
    [B, FitInfo] = lassoglm(X_train,y_train,'binomial','NumLambda',options.nlambda,'CV',CVB);
    coef = [FitInfo.Intercept(FitInfo.IndexMinDeviance); B(:,FitInfo.IndexMinDeviance)];
    y_hat = glmval(coef,X_test,'logit');
    min_lambda = FitInfo.Lambda(FitInfo.IndexMinDeviance);
    %     lassoPlot(B,FitInfo,'plottype','CV');
else
    error('Method name unrecognizable.');
end

% save coeff
results.lasso_lambda_min = min_lambda;
results.lasso_coef_lambda_min = coef;
y_hat = thresholding(y_hat);
results.lasso_accuracy_lambda_min = sum(y_hat == y_test) / length(y_test);
end

function y_thresholded = thresholding(y_raw_prediction)
    y_thresholded = round(y_raw_prediction);
end


