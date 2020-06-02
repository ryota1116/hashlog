import axios from "axios"
const csrfToken = document
  .querySelector('meta[name="csrf-token"]')
  .getAttribute("content")

axios.defaults.headers.common = {
  "X-Requested-With": "XMLHttpRequest",
  "X-CSRF-Token": csrfToken
}

const state = () => ({
  currentUser: ""
})

const getters = {
  currentUser: state => state.currentUser
}

const mutations = {
  setCurrentUser(state, user) {
    state.currentUser = user
  }
}

const actions = {
  getCurrentUser({ dispatch, state }) {
    const { currentUser } = state
    if (currentUser) {
      return currentUser
    }
    return dispatch("getCurrentUserFromAPI")
  },
  async getCurrentUserFromAPI({ commit }) {
    try {
      const response = await axios.get("/api/v1/users/current")
      commit("setCurrentUser", response.data.user)
      return response.data.user
    } catch (err) {
      commit("setCurrentUser", null)
      return null
    }
  },
  async updateCurrentUser({ commit, state }, userData) {
    try {
      const response = await axios.patch(
        `/api/v1/users/${state.currentUser.uuid}`,
        {
          user: userData
        }
      )
      commit("setCurrentUser", response.data.user)
      return response.data.user
    } catch (error) {
      return null // バリデーションエラー
    }
  },
  async deleteCurrentUser({ commit, state }) {
    await axios.delete(`/api/v1/users/${state.currentUser.uuid}`)
    commit("setCurrentUser", null)
  },
  async logout({ commit }) {
    await this.$axios.delete("/api/v1/user_session")
    commit("setCurrentUser", null)
  }
}

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions
}