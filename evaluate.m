function [evaluation] = evaluate(predicted_label, true_label)
[class_accuracies class_list] = get_class_accuracies(predicted_label, true_label);
[confusion_matrix class_list2] = get_confusion_matrix(predicted_label, true_label);

assert(all(class_list == class_list2), 'class_list and class_list2 are not equal!');

evaluation.class_list = class_list;
evaluation.class_accuracies = class_accuracies;
evaluation.mean_class_accuracy = mean(class_accuracies);
evaluation.confusion_matrix = confusion_matrix;

end


function [class_accuracies class_list] = get_class_accuracies(predicted_label, true_label)
class_list = unique([predicted_label; true_label]);
class_accuracies = zeros(length(class_list), 1);
for i=1:length(class_list)
   curr_class = class_list(i);
   true_class_binary = (true_label == curr_class);
   num_class = sum(true_class_binary);
   
   predicted_class_binary = (predicted_label == curr_class);
   num_correct_class = sum(predicted_class_binary & true_class_binary);
   
   class_accuracies(i) = num_correct_class/num_class;
end
end

function [confusion_matrix, class_list] = get_confusion_matrix(predicted_label, true_label)
class_list = unique([predicted_label; true_label]);
confusion_matrix = zeros(length(class_list), length(class_list));
for i=1:length(class_list)
   curr_true_class = class_list(i);
   true_class_binary = (true_label == curr_true_class);
   
   for j=1:length(class_list)
      curr_predicted_class = class_list(j);
      predicted_class_binary = (predicted_label == curr_predicted_class);
      
      confusion_matrix(i,j) = sum(true_class_binary & predicted_class_binary);
   end
end
end