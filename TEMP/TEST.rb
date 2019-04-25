a = [[:mhp, 2], [:atk, 1], [0,1,3]]
b = [[:atk, 1], [0,1,3], [:mhp, 2]]
p a.sort_by(&:hash) == b.sort_by(&:hash)
