import matplotlib.pyplot as plt
import numpy as np

TOTAL_SAMPLES = 1000

data = {
    'JS': {
        'old_engine': {
            'exponential': 385,
            'high_polynomial': 90,
            'low_polynomial': 0,
            'linear': 500,
            'total': 975
        },
        'new_engine': {
            'exponential': 0,
            'high_polynomial': 136,
            'low_polynomial': 464,
            'linear': 369,
            'total': 969
        }
    },
    'Ruby': {
        'old_engine': {
            'exponential': 347,
            'high_polynomial': 88,
            'low_polynomial': 5,
            'linear': 535,
            'total': 975
        },
        'new_engine': {
            'exponential': 23,
            'high_polynomial': 5,
            'low_polynomial': 297,
            'linear': 650,
            'total': 975
        }
    },
    'C#': {
        'old_engine': {
            'exponential': 368,
            'high_polynomial': 79,
            'low_polynomial': 51,
            'linear': 469,
            'total': 967
        },
        'new_engine': {
            'exponential': 0,
            'high_polynomial': 0,
            'low_polynomial': 67,
            'linear': 897,
            'total': 964
        }
    },
    'Java': {
        'old_engine': {
            'exponential': 385,
            'high_polynomial': 165,
            'low_polynomial': 10,
            'linear': 422,
            'total': 982
        },
        'new_engine': {
            'exponential': 92,
            'high_polynomial': 460,
            'low_polynomial': 2,
            'linear': 428,
            'total': 982
        }
    },
    'PHP': {
        'old_engine': {
            'exponential': 0,
            'high_polynomial': 16,
            'low_polynomial': 17,
            'linear': 949,
            'total': 982
        },
        'new_engine': {
            'exponential': 0,
            'high_polynomial': 18,
            'low_polynomial': 8,
            'linear': 946,
            'total': 972
        }
    },
    'Perl': {
        'old_engine': {
            'exponential': 2,
            'high_polynomial': 150,
            'low_polynomial': 154,
            'linear': 676,
            'total': 982
        },
        'new_engine': {
            'exponential': 7,
            'high_polynomial': 259,
            'low_polynomial': 101,
            'linear': 615,
            'total': 982
        }
    },
    'Python': {
        'old_engine': {
            'exponential': 386,
            'high_polynomial': 78,
            'low_polynomial': 45,
            'linear': 447,
            'total': 956
        },
        'new_engine': {
            'exponential': 371,
            'high_polynomial': 78,
            'low_polynomial': 43,
            'linear': 464,
            'total': 956
        }
    },
    'Rust': {
        'old_engine': {
            'exponential': 0,
            'high_polynomial': 0,
            'low_polynomial': 0,
            'linear': 712,
            'total': 712
        },
        'new_engine': {
            'exponential': 0,
            'high_polynomial': 0,
            'low_polynomial': 1,
            'linear': 966,
            'total': 967
        }
    },
    'Go': {
        'old_engine': {
            'exponential': 0,
            'high_polynomial': 0,
            'low_polynomial': 20,
            'linear': 953,
            'total': 973
        },
        'new_engine': {
            'exponential': 0,
            'high_polynomial': 0,
            'low_polynomial': 0,
            'linear': 973,
            'total': 973
        }
    }
}

languages = list(data.keys())
n_groups = len(languages)

fig, ax = plt.subplots(figsize=(10, 4))

index = np.arange(n_groups)
bar_width = 0.30
gap = 0.05
opacity = 0.8

cmap = plt.get_cmap('tab10')
colors = [cmap(i) for i in range(4)]

for i, lang in enumerate(languages):
    old_engine = list(data[lang]['old_engine'].values())
    new_engine = list(data[lang]['new_engine'].values())

    linear_old = (data[lang]['old_engine']['linear'] / data[lang]['old_engine']['total']) * 100
    low_polynomial_old = (data[lang]['old_engine']['low_polynomial'] / data[lang]['old_engine']['total']) * 100
    high_polynomial_old = (data[lang]['old_engine']['high_polynomial'] / data[lang]['old_engine']['total']) * 100
    exponential_old = (data[lang]['old_engine']['exponential'] / data[lang]['old_engine']['total']) * 100

    linear_new = (data[lang]['new_engine']['linear'] / data[lang]['new_engine']['total']) * 100
    low_polynomial_new = (data[lang]['new_engine']['low_polynomial'] / data[lang]['new_engine']['total']) * 100
    high_polynomial_new = (data[lang]['new_engine']['high_polynomial'] / data[lang]['new_engine']['total']) * 100
    exponential_new = (data[lang]['new_engine']['exponential'] / data[lang]['new_engine']['total']) * 100

    plt.bar(index[i] - bar_width/2 - gap, low_polynomial_old, bar_width, alpha=opacity, label='Low Polynomial', color=colors[0])
    plt.bar(index[i] - bar_width/2 - gap, high_polynomial_old, bar_width, alpha=opacity, label='High Polynomial', bottom=low_polynomial_old, color=colors[1])
    plt.bar(index[i] - bar_width/2 - gap, exponential_old, bar_width, alpha=opacity, label='Exponential', bottom=low_polynomial_old + high_polynomial_old, color=colors[2])
    plt.text(index[i] - bar_width/2 - gap, -3, f'{"Old"}', ha='center', va='center', color='black', fontsize=12, fontstyle='italic')

    plt.bar(index[i] + bar_width/2 + gap, low_polynomial_new, bar_width, alpha=opacity, label='Low Polynomial', color=colors[0])
    plt.bar(index[i] + bar_width/2 + gap, high_polynomial_new, bar_width, alpha=opacity, label='High Polynomial', bottom=low_polynomial_new, color=colors[1])
    plt.bar(index[i] + bar_width/2 + gap, exponential_new, bar_width, alpha=opacity, label='Exponential', bottom=low_polynomial_new + high_polynomial_new, color=colors[2])
    plt.text(index[i] + bar_width/2 + gap, -3, f'{"New"}', ha='center', va='center', color='black', fontsize=12, fontstyle='italic')


plt.ylabel('% of Super-Linear\nRegex Candidates', fontsize=18)
plt.tick_params(axis='x', which='major', pad=12, labelsize=18)
plt.xticks(index, languages)
plt.tick_params(axis='y',labelsize=16)
plt.yticks(np.arange(0, 76, 25))
# plt.legend()

# Create a custom legend
handles, labels = plt.gca().get_legend_handles_labels()
# Get only the first three items
handles = handles[0:3]
labels = labels[0:3]
plt.legend(handles[::-1], labels[::-1], loc='upper right', ncol=3, fontsize=16, bbox_to_anchor=(0.96, 1.225))

plt.tight_layout()
plt.savefig('figure_5.png', dpi=600)

# Save as pdf
plt.savefig('figure_5.pdf', format='pdf', dpi=600)